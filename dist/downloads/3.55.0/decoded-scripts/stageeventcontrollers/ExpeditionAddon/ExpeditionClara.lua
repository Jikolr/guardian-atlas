local local_class = newclass('ExpeditionClara')

function local_class:on_load_resource_routine(params)
	self.global_key = 'conquest_screenplay'

	self.hidden_event_state = {
		none = 1,
		blocked = 2,
		cleared = 3
	}
	self.current_hidden_event_state = self.hidden_event_state.none

	-- 타겟될 몬스터 찾아서 세트 해야 함.
	local bosses = stage:GetBossCharacters()
	for i = 0, bosses.Count - 1 do
		if bosses[i].CharacterStatsBehaviour.FieldObjectSpec.Id == params.boss_phase1_id then
			self.boss_phase1 = get_character(bosses[i].Name)
			message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_fo_destroyed_event')
		elseif bosses[i].CharacterStatsBehaviour.FieldObjectSpec.Id == params.boss_phase2_id then
			self.boss_phase2 = get_character(bosses[i].Name)
			message_system:Subscribe(self, typeof(CS.Oak.ExpeditionMonsterSpawnedEvent), 'on_monster_spawned_event')
		end
	end

	CS.UnityEngine.Debug.Assert(self.boss_phase1 ~= nil and self.boss_phase2 ~= nil, 'Cannot Find Stage Boss')

	local zone_1 = field:GetZone(params.boss_phase1_zone_name)
	local zone_2 = field:GetZone(params.boss_phase2_zone_name)
	self.phase1_zone = zone_1 and zone_1.Bounds or CS.UnityEngine.Bounds(self.boss_phase1.Position, unity_class.vector3(5, 5, 10))
	self.phase2_zone = zone_2 and zone_2.Bounds or CS.UnityEngine.Bounds(zone_1.Bounds.center, unity_class.vector3(10, 5, 10))

	self.boss_phase1.FieldObjectController.Zone = params.boss_phase1_zone_name
	self.boss_phase2.FieldObjectController.Zone = params.boss_phase2_zone_name

	-- 이펙트
	self.left_wall_fx_pool = unity_object_pool.GetOrCreate('fx_boss_clara_appear_chain_l')
	self.right_wall_fx_pool = unity_object_pool.GetOrCreate('fx_boss_clara_appear_chain_r')
	self.fx_black_out_pool = unity_object_pool.GetOrCreate('fx_boss_clara_phase2_screen')
	self.fx_black_out_fire_pool = unity_object_pool.GetOrCreate('fx_boss_clara_phase2_screen_fire')
	self.fx_black_out_fire_end_pool = unity_object_pool.GetOrCreate('fx_boss_clara_phase2_screen_fire_end')

	self.appear_camera_magnitude = params.appear_camera_magnitude
	self.appear_camera_duration = params.appear_camera_duration

	-- 사운드
	music_player:PreloadMusic('bgm_expedition_boss_07')
	music_player:PreloadSfx('02_clara_boss_event_01')
	music_player:PreloadSfx('02_clara_boss_event_02')
	music_player:PreloadSfx('02_clara_boss_event_03')
	music_player:PreloadSfx('01_catch_fire_01')

	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExpeditionEndEvent), 'on_expedition_end_event')

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.spawn_knight_captain_routine, self, params.knight_captain_id))

	-- 4지역 히든 이벤트 B
	self.use_hidden_b_effect = params.use_hidden_b_effect
	self:init_hidden_event(params.s4_hidden_b_hp, params.s4_hidden_b_hp_bar_height, params.s4_hidden_b_hp_bar_width)

	-- 스테이지 틴트
	local original_stage_tint_vector = unity_class.vector3(140,140,140)
	local r = params.stage_tint_r / original_stage_tint_vector.x
	local g = params.stage_tint_g / original_stage_tint_vector.y
	local b = params.stage_tint_b / original_stage_tint_vector.z
	self.stage_tint_color = unity_color({r,g,b,1})
	self.stage_tint = {
		tint_key = 'expedition_s4_clara',
		mpb = CS.UnityEngine.MaterialPropertyBlock(),
		renderer_list = {},
		is_applied = false,
		add_renderer = function(self, renderer) -- 틴트 같이 적용할 렌더러 추가
			table.insert(self.renderer_list, renderer)
		end,
		remove_renderer = function(self, renderer)
			for i = #self.renderer_list, 1, -1 do
				local r = self.renderer_list[i]
				if lua_helper.reference_equals(renderer, r) then
					table.remove(self.renderer_list, i)
					return
				end
			end
		end,
		apply_tint = function(self, color)
			self.is_applied = true
			field:Tint(self.tint_key, color, 0)
			self.mpb:SetColor(CS.UnityEngine.Shader.PropertyToID('_Color'), color);
			for _, renderer in ipairs(self.renderer_list) do
				renderer:SetPropertyBlock(self.mpb)
			end
		end,
		remove_tint = function(self)
			self.is_applied = false
			field:RemoveTint(self.tint_key, 0)
			for _, renderer in ipairs(self.renderer_list) do
				renderer:SetPropertyBlock(nil)
			end
		end,
		dispose = function(self)
			if self.is_applied then
				self:remove_tint()
			end

			for i = #self.renderer_list, 1, -1 do
				self.renderer_list[i] = nil
				self.renderer_list = nil
			end
			self.mpb:Clear()
			self.mpb = nil
		end
	}
end

--region event
function local_class:on_monster_spawned_event(e)
	-- 2페이즈 보스 비활성화
	if e.Monster == self.boss_phase2 then
		message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionMonsterSpawnedEvent))
		message_system:Publish(CS.Oak.MonsterGiveUpEvent.Create(self.boss_phase2, false))
		character_util.set_active_state(self.boss_phase2, 'disabled')
	end
end

function local_class:on_fo_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, self.boss_phase1) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_first_phase_end_routine, self))
	elseif lua_helper.reference_equals(e.FieldObject, self.boss_phase2) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_second_phase_end_routine, self))
	end
end

function local_class:on_battle_start_event(e)
	if self.stage_ended then
		return
	end

	local current_battle = e.StartedBattle

	-- npc 에바 전투 참여
	if current_battle.IsPlayerBattle and not CS.Oak.BattleCharacterStatusExtensions.Contains(current_battle.Allies, self.knight_captain) then
		current_battle:AddAlly(self.knight_captain)
		message_system:SendSync(self.knight_captain.FieldObjectController, CS.Oak.StateResetEvent.Instance)
	end
end

function local_class:on_battle_end_event(e)
	-- npc 에바 리셋
	if e:IsCharacterInBattle(self.knight_captain) then
		message_system:SendSync(self.knight_captain.FieldObjectController, CS.Oak.StateResetEvent.Instance)
	end
end

function local_class:on_expedition_end_event(e)
	self.stage_ended = true

	-- 스테이지 종료 추가 연출
	local play_result = e.PlayResult
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.expedition_end_routine, self, play_result))
end
--endregion

--region boss_gimmick_npc
function local_class:spawn_knight_captain_routine(knight_captain_id)
	local spec = CS.Oak.GameDataService.GetData('Characters'):GetSpec(knight_captain_id)
	local loader = CS.Oak.CharacterLoader(spec)
	local stage_data = game_data_service.GetData('StageData')
	local exps_data = game_data_service.GetData('ExpsData')
	local exp = 80
	local stage_level = stage_data:GetStage(stage.StageId).StageStandardLevel
	if stage ~= nil then
		if stage_data:GetStage(stage.StageId) ~= nil then
			exp = CS.Oak.ExpsDataLevelExpExtensions.GetTotalExpForLevel(exps_data, stage_level)
		end
	end

	coroutine.yield(loader)

	self.knight_captain = loader.Character

	self.knight_captain.Name = 'npc_knight_captain'
	self.knight_captain.FieldObjectBehaviour = CS.Oak.CharacterBehaviour();
	self.knight_captain.FieldObjectController = CS.Oak.MonsterCharacterController()
	self.knight_captain.CrashBehaviour = CS.Oak.PassCharacterCrashBehaviour.Instance
	self.knight_captain.DamagedBehaviour = CS.Oak.CharacterDamagedBehaviour.Create()
	self.knight_captain.FieldObjectStatsBehaviour:AddExp(exp)

	local weapon1_spec = CS.Oak.ItemSpec.GetByName('cwp_knightcaptain_epic')
	local weapon1 = weapon_util.create_monster_weapon({spec = weapon1_spec, level = stage_level})
	self.knight_captain:SetEquipment(CS.Oak.EquipmentSlot.Weapon1, weapon1, false)

	coroutine.yield(self.knight_captain:UpdateAndBattleAndStageOptions())

	self.knight_captain.Position = field:GetMarker('spawn_npc').position
	self.knight_captain.Direction = CS.Oak.Direction.Up
	self.knight_captain.Owner = CS.Oak.Player.Local
	CS.Oak.NetworkEntityManager.Instance:RegisterEntity(self.knight_captain)

	self.knight_captain.EntityGroup = CS.Oak.EntityGroups.Player0
	self.knight_captain.Interactable = CS.Oak.NonInteractable.Instance
	self.knight_captain.CharacterStatsBehaviour:AddStatsOptionRequest(
			stage.StageGameObject, CS.Oak.CharacterStatsOptions.Invincible)

	character_util.set_active_state(self.knight_captain, 'enabled')
end

function local_class:expedition_end_routine(play_result)
	coroutine.yield(nil)

	local character = self.knight_captain
	CS.Oak.CharacterControllerScreenplayState.Stop(character)

	character_util.set_direction(character, direction_util.to_side_dir(character.Direction))
	if play_result == CS.Oak.ExpeditionStage.Result.TimeOutFail then
		character_util.set_anim_and_emotion(character,
				{name = 'hurt', priority = CS.Oak.AnimationPriorities.Custom, loop = false},
				{name = 'tired', priority = CS.Oak.AnimationPriorities.Custom, loop = false})
	elseif play_result == CS.Oak.ExpeditionStage.Result.Clear then
		coroutine.yield(coroutine_class.wait_for_sec(2.5))
		character_util.set_anim_and_emotion(character,
				{name = 'victory_get', priority = CS.Oak.AnimationPriorities.Custom, loop = false},
				{name = 'smile', priority = CS.Oak.AnimationPriorities.Custom, loop = false})
	elseif play_result == CS.Oak.ExpeditionStage.Result.Defeated then
		character_util.set_anim_and_emotion(character,
				{name = 'hurt', priority = CS.Oak.AnimationPriorities.Custom, loop = false},
				{name = 'tired', priority = CS.Oak.AnimationPriorities.Custom, loop = false})
	end
end
--endregion

--region screen_play
-- fade in 전 연출 시작
function local_class:pre_launch_routine()
	local spawn_marker = field:GetMarker('spawn_1')
	self.boss_phase1.Position = spawn_marker.position
	self.boss_phase1.ActiveState = CS.Oak.ActiveState.Visible
	character_util.set_locked_dir(self.boss_phase1, 'down')
	CS.Oak.PartyManager.Instance[0]:StopAndDisableControl()
	character_util.set_anim(self.boss_phase1, {name = 'appear_phase1', loop = false})
	self.original_time_scale = self.boss_phase1.SpineController.TimeScale
	self.boss_phase1.SpineController.TimeScale = 0

	stage.BattleManager.PlayBattleVoiceAndFanfare = false
	stage.BattleManager.DontMovePartyOnBattleStart = true

	-- 벽 생성
	local wall_fx_offset = unity_class.vector3(0,0,-6.6)
	local hit_box = CS.Oak.Hitbox(vector(1, 2, self.phase1_zone.size.z))
	local left_pos = unity_class.vector3(self.phase1_zone.min.x, 0, self.phase1_zone.center.z)
	local right_pos = unity_class.vector3(self.phase1_zone.max.x, 0, self.phase1_zone.center.z)

	self.wall_left = CS.Oak.VirtualFieldObject()
	self.wall_left.Position = left_pos
	self.wall_left.Hitbox = hit_box
	self.wall_left.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	self.wall_left.ActiveState = CS.Oak.ActiveState.Enabled

	self.wall_right = CS.Oak.VirtualFieldObject()
	self.wall_right.Position = right_pos
	self.wall_right.Hitbox = hit_box
	self.wall_right.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	self.wall_right.ActiveState = CS.Oak.ActiveState.Enabled

	if self.left_wall_fx_pool then
		self.left_wall_fx = object_pool_extensions.Instantiate(self.left_wall_fx_pool, left_pos + wall_fx_offset)
	end
	if self.right_wall_fx_pool then
		self.right_wall_fx = object_pool_extensions.Instantiate(self.right_wall_fx_pool, right_pos + wall_fx_offset)
	end

	-- 멥 어둡게
	--local left_renderers = self.left_wall_fx.transform:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))
	--local right_renderers = self.right_wall_fx.transform:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))
	--for i = 0, left_renderers.Length - 1 do
	--	local renderer = left_renderers[i]
	--	self.stage_tint:add_renderer(renderer)
	--end
	--for i = 0, right_renderers.Length - 1 do
	--	local renderer = right_renderers[i]
	--	self.stage_tint:add_renderer(renderer)
	--end
	self.stage_tint:apply_tint(self.stage_tint_color)

	if self.hidden_event_ready and self.use_hidden_b_effect then
		while not CS.Oak.UnityObjectPoolExtensions.IsLoaded(
				unity_object_pool.GetOrCreate('fx_expedition_gimmick_hole_light')) do
			coroutine.yield(nil)
		end
		self.hidden_b_light_fx = unity_object_pool.GetOrCreate('fx_expedition_gimmick_hole_light'):Instantiate(
				self.collapsed_wall.fo.Bounds.center:GetX0z(self.collapsed_wall.fo.Position.y + 0.05),
				unity_class.quaternion.identity, self.collapsed_wall.fo.transform)
	end
end

function local_class:on_launch_routine()
	-- 보스 시작 애니메이션 재개
	self.boss_phase1.SpineController.TimeScale = self.original_time_scale
	music_player:PlaySfxOneShot('02_clara_boss_event_01')

	-- appear 종료
	wait_for_sec(1.7)
end

-- 전투 시작 전 정리
function local_class:post_launch_routine()
	-- 보스 나머지 사항 복구
	field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.CharacterStats, self.boss_phase1)
	--message_system:SendSync(self.boss_phase1, CS.Oak.StateResetEvent.Instance)

	character_util.remove_anim(self.boss_phase1)
	character_util.set_locked_dir(self.boss_phase1, 'down')

	CS.Oak.PartyManager.Instance[0]:ResetControllers()
end

function local_class:on_first_phase_end_routine()
	message_system:PublishSync(CS.Oak.GlobalTimerRequestPauseEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
	music_player_util.play_stage_music({ state = 'muted', mix = 0 })

	-- 배틀 종료 사운드 다시 키기
	stage.BattleManager.PlayBattleVoiceAndFanfare = true

	-- 1초
	character_util.set_anim(self.boss_phase1, {name = 'dead', loop = false})
	music_player:PlaySfxOneShot('02_clara_boss_event_01')

	local phase2_pos = field:GetMarker('spawn_2').position
	camera_util.move(self.boss_phase1.Position, 2, { ignorecameragrids = true })

	local party = CS.Oak.PartyManager.Instance[0]
	local member_count = 0
	for i = 0, party.Count - 1 do
		local character = party[i]

		if character and not character.FieldObjectStatsBehaviour.IsDead then
			member_count = member_count + 1
			CS.Oak.CharacterControllerScreenplayState.Stop(character)
		end
	end
	CS.Oak.CharacterControllerScreenplayState.Stop(self.knight_captain)

	coroutine.yield(nil)

	for i = 0, party.Count - 1 do
		local character = party[i]
		if character then
			if character.FieldObjectStatsBehaviour.IsDead then
				message_system:SendSync(character.FieldObjectController,
						CS.Oak.StateChangeEvent.Create(CS.Oak.CharacterControllerDeadState.Instance))
				message_system:SendSync(character.FieldObjectBehaviour,
						CS.Oak.StateChangeEvent.Create(CS.Oak.HeroDeadState.Create(character)))
			end
		end
	end

	local npc_pos = field:GetMarker('phase2_npc_pos').position
	local direction = CS.Oak.Direction.Up

	-- 사망 연출 대기
	wait_for_sec(0.6)

	-- 암전
	local black_out = object_pool_extensions.Instantiate(self.fx_black_out_pool, phase2_pos + unity_class.vector3.forward)

	wait_for_sec(0.4)

	-- 완전 암전 후 카메라 재조정
	camera_util.move(phase2_pos + unity_class.vector3.forward * 2, 0, { ignorecameragrids = true })
	camera_util.resize_to(5, 0)

	-- 2페이즈 보스 준비
	self.boss_phase2.Position = phase2_pos
	self.boss_phase2.Direction = CS.Oak.Direction.Down
	self.boss_phase2.FieldObjectController.NoReturnFlag = true
	character_util.set_active_state(self.boss_phase2, 'visible')

	-- bone follower
	local body_eff_follower = CS.UnityEngine.GameObject('body_effect_follower')
	body_eff_follower.transform.parent = self.boss_phase2.transform
	local bone_follower = body_eff_follower:AddComponent(typeof(CS.Spine.Unity.BoneFollower))
	local spine = self.boss_phase2.SpineController
	bone_follower.followBoneRotation = false
	bone_follower.SkeletonRenderer = spine.SkeletonAnimation
	bone_follower:SetBone('head')

	coroutine.yield(nil)

	-- 2페이즈 보스 암전 불 이펙트
	-- 0.33, 0.80, 1.22 불 점화 sfx, 프레임 시간 오차 해결하지 않음
	local black_out_fire_fx = self.fx_black_out_fire_pool:Instantiate(
			body_eff_follower.transform.position + unity_class.vector3.up * 0.4,
			unity_class.quaternion.identity, body_eff_follower.transform)

	-- 암전 연출 대기1
	wait_for_sec(0.33)
	music_player:PlaySfxOneShot('01_catch_fire_01')

	black_out.transform.position = black_out_fire_fx.transform.position

	-- 플레이어 파티 위치로
	local direction_vector = direction_util.to_vector3(direction)
	local distance = CS.Oak.Constants.DistBetweenPartyMembers
	local align_pos = field:GetMarker('phase2_player_pos').position + direction_vector * distance
	local align_index = 0

	--- 파티 정렬
	for i = 0, party.Count - 1 do
		local character = party[i]

		if character and not character.FieldObjectStatsBehaviour.IsDead then
			align_index = align_index + 1
			character.Position = self:get_align_pos(align_pos, direction_vector, align_index, member_count, distance)
			character.Direction = direction
		end
	end
	self.knight_captain.Position = npc_pos

	-- 1페이즈 보스 제거
	character_util.set_active_state(self.boss_phase1, 'disabled')

	-- 체인 벽 제거
	self.wall_left.ActiveState = CS.Oak.ActiveState.Disabled
	self.wall_right.ActiveState = CS.Oak.ActiveState.Disabled
	self.wall_left:Dispose()
	self.wall_right:Dispose()
	self.left_wall_fx:Dispose()
	self.right_wall_fx:Dispose()
	self.left_wall_fx = nil
	self.right_wall_fx = nil

	-- 틴트 제거
	self.stage_tint:remove_tint()

	-- 암전 연출 대기2
	wait_for_sec(0.47)
	music_player:PlaySfxOneShot('01_catch_fire_01')

	-- 암전 연출 대기3
	wait_for_sec(0.42)
	music_player:PlaySfxOneShot('01_catch_fire_01')

	-- 암전 연출 대기4
	wait_for_sec(0.71)
	music_player:PlaySfxOneShot('02_clara_boss_event_02')

	-- 암전 연출 대기5
	wait_for_sec(0.27)

	-- 암전 불 연출 종료
	self.fx_black_out_fire_end_pool:Instantiate(
			body_eff_follower.transform.position + unity_class.vector3.up * 0.4,
			unity_class.quaternion.identity, body_eff_follower.transform)
	wait_for_sec(0.5)
	black_out_fire_fx:Dispose()

	-- 2페이즈 보스 애니메이션 연출 준비
	character_util.set_anim(self.boss_phase2, {name = 'appear_phase_2', loop = false})

	-- 암전 해제
	camera_util.resize_to(7, 1)
	wait_for_sec(0.1)
	self.boss_phase2.SpineController.TimeScale = 0
	wait_for_sec(0.3)

	-- 2페이즈 bgm
	local data = { name = 'ondemand/expedition/audio:bgm_expedition_boss_07', state = 'combat', mix = 0 }
	music_player_util.play_stage_music(data)

	-- 2페이즈 보스 애니메이션 연출
	self.boss_phase2.SpineController.TimeScale = 1
	wait_for_sec(0.4)

	-- 카메라 원위치
	camera_util.move(nil, 0.2, { target = party, end_target = party })
	wait_for_sec(0.2)

	character_util.set_active_state(self.boss_phase2, 'enabled')

	black_out:Dispose()
	CS.UnityEngine.Object.Destroy(body_eff_follower)

	character_util.remove_anim(self.boss_phase2)

	for i = 0, party.Count - 1 do
		local character = party[i]
		if character then
			if not character.FieldObjectStatsBehaviour.IsDead then
				message_system:SendSync(character.FieldObjectController, CS.Oak.StateResetEvent.Instance)
			end
		end
	end

	-- 전투 Notice 강제 발생
	local cmd = CS.Oak.MonsterNoticeCommand.Create(self.boss_phase2, party.Leader, CS.Oak.MonsterNoticeLevel.Battle)
	command_util.execute_cmd(cmd)

	message_system:PublishSync(CS.Oak.GlobalTimerRequestResumeEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
end

function local_class:on_second_phase_end_routine()
	music_player_util.play_stage_music({ state = 'muted', mix = 0 })
	character_util.set_anim(self.boss_phase2, {name = 'dead', loop = false, next_anim = 'groggy'})
	wait_for_sec(0.567)
	music_player:PlaySfxOneShot('02_clara_boss_event_03')
end

function local_class:get_align_pos(pos, direction, index, member_count, distance)
	if index < 0 or index >= member_count then
		return pos
	end

	if member_count == 2 then
		return pos + direction * index * distance
	elseif member_count == 3 then
		return pos + unity_class.quaternion.AngleAxis(index == 1 and -45 or 45, unity_class.vector3.up)
				* direction * distance
	elseif member_count == 4 then
		if index == 1 then
			return pos + unity_class.quaternion.AngleAxis(-60, unity_class.vector3.up) * direction * distance
		elseif index == 2 then
			return pos + direction * distance
		elseif index == 3 then
			return pos + unity_class.quaternion.AngleAxis(60, unity_class.vector3.up) * direction * distance
		end
	end
end
--endregion

function local_class:is_hittable_to(attacker, target)
	if is_unity_null(target) then
		return false
	end

	if target.FieldObjectStatsBehaviour.IsDead then
		return false
	end

	if lua_helper.reference_equals(attacker, target) then
		return false
	end

	return CS.Oak.EntityGroupsExtensions.IsHittableTo(attacker.EntityGroup, target.EntityGroup)
end

function local_class:late_update_frame(dt)
	--self:update_chain(dt)
end

function local_class:on_stage_end()
end

-- 호출 시점, 이펙트 붙인것 등을 제거해준다.
function local_class:on_dispose()
	self.boss_phase1 = nil
	self.boss_phase2 = nil
	self.knight_captain = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionMonsterSpawnedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.stage_tint_color = nil
	if self.stage_tint then
		self.stage_tint:dispose()
		self.stage_tint = nil
	end

	if self.collapsed_wall then
		if self.gauge_bar then
			field_ui_manager:RemoveUI(self.collapsed_wall.fo, CS.Oak.FieldUiType.TimerBar)
			self.gauge_bar = nil
		end

		self.collapsed_wall:dispose()
		self.collapsed_wall = nil
	end

	self.phase1_zone = nil
	self.phase2_zone = nil

	if self.wall_left then
		self.wall_left:Dispose()
		self.wall_left = nil
	end

	if self.wall_right then
		self.wall_right:Dispose()
	end

	if self.left_wall_fx then
		self.left_wall_fx:Dispose()
		self.left_wall_fx = nil
	end

	if self.right_wall_fx then
		self.right_wall_fx:Dispose()
		self.right_wall_fx = nil
	end

	self.left_wall_fx_pool = nil
	self.right_wall_fx_pool = nil
	self.fx_black_out_pool = nil
	self.fx_black_out_fire_pool = nil
	self.fx_black_out_fire_end_pool = nil
end

--region hidden_b
function local_class:init_hidden_event(hp, hp_bar_height, hp_bar_width)
	local collapsed_wall = get_field_object('event_hidden_collapsed_wall')

	if not collapsed_wall then
		return
	end

	self.collapsed_wall = {
		fo = collapsed_wall,
		on = collapsed_wall.Transform:Find('on'),
		off = collapsed_wall.Transform:Find('off'),
		change_state = function(this, new_state)
			if not this.is_ready then
				return
			end

			if new_state == self.hidden_event_state.cleared then
				this.off.gameObject:SetActive(false)
			elseif new_state == self.hidden_event_state.blocked then
				this.off.gameObject:SetActive(true)
			end
		end,
		dispose = function(this)
			this.fo = nil
			this.on = nil
			this.off = nil
		end,
		is_ready = nil
	}

	self.collapsed_wall.is_ready = is_unity_null(self.collapsed_wall['on']) == false and
			is_unity_null(self.collapsed_wall['off']) == false

	if stage.HiddenEventCleared then
		self:change_hidden_event_state(self.hidden_event_state.cleared)
	else
		self:change_hidden_event_state(self.hidden_event_state.blocked)
	end

	if stage.PlayHiddenEvent then
		if self.current_hidden_event_state == self.hidden_event_state.cleared
				or not self.collapsed_wall.is_ready then
			return
		end
		self.hidden_event_ready = true

		music_player:PreloadSfx('03_rock_break_03')
		unity_object_pool.GetOrCreate('fx_expedition_collapsed_wall_s4')
		if self.use_hidden_b_effect then
			unity_object_pool.GetOrCreate('fx_expedition_gimmick_hole_light')
		end

		local ui_dic = field_ui_manager:SetUI(self.collapsed_wall.fo, CS.Oak.FieldUiType.TimerBar)

		-- 게이지 최대
		self.gauge_total = hp
		-- 게이지 바 높이
		local gauge_bar_height = hp_bar_height
		local gauge_bar_width = hp_bar_width

		self.gauge_bar = ui_dic[CS.Oak.FieldUiType.TimerBar]
		self.gauge_bar.BarSprite:SetWidth(gauge_bar_width)
		self.gauge_bar.BarSprite:SetMinMax(0, self.gauge_total)
		self.gauge_bar.BarSprite:SetValue(self.gauge_total, 0)
		self.gauge_bar.BarSprite.Transform.position = self.collapsed_wall.fo.Bounds.center + unity_class.vector3(0,gauge_bar_height,0)
		self.gauge_bar.BarSprite.Transform.gameObject:SetActive(false)

		self.current_gauge = self.gauge_total

		message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	end
end

function local_class:on_custom_stage_event(e)
	if e:GetType() == typeof(CS.Oak.CustomStageEvent) then
		if stage.PlayHiddenEvent and e:GetParamAt(0) == 'expedition_s4_hidden_event_b_damage' then
			local damage = tonumber(e:GetParamAt(1))
			if self.current_gauge > 0 then
				if self.current_gauge == self.gauge_total then
					self.gauge_bar.BarSprite.Transform.gameObject:SetActive(true)
				end
				self.current_gauge = self.current_gauge - damage
				self.gauge_bar.BarSprite:SetValue(self.current_gauge, 0)

				if self.current_gauge <= 0 then
					self:clear_event()
				end
			end
		end

		return true
	end

	return false
end

function local_class:clear_event()
	if self.current_hidden_event_state == self.hidden_event_state.cleared
			or not stage.PlayHiddenEvent or stage.HiddenEventCleared then
		return
	end

	self:change_hidden_event_state(self.hidden_event_state.cleared)
	object_pool_extensions.Instantiate(unity_object_pool.GetOrCreate('fx_expedition_collapsed_wall_s4'),
			self.collapsed_wall.fo.transform.position)
	music_player_util.play_sfx_one_shot('03_rock_break_03')
	stage:ClearHiddenEvent()

	if self.hidden_b_light_fx then
		self.hidden_b_light_fx:Dispose()
		self.hidden_b_light_fx = nil
	end

	-- 게이지바 숨기기
	self.gauge_bar.BarSprite.Transform.gameObject:SetActive(false)
end

function local_class:change_hidden_event_state(next_state)
	if self.current_hidden_event_state == next_state then
		return
	end

	if next_state == self.hidden_event_state.cleared then
		self.collapsed_wall:change_state(next_state)
		self.current_gauge = 0
	elseif next_state == self.hidden_event_state.blocked then
		self.collapsed_wall:change_state(next_state)
	end

	self.current_hidden_event_state = next_state
end
--endregion

return {
	create = function()
		return local_class()
	end
}
