local local_class = newclass("LilithTowerMetalGearSolid")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- Constants
	self.common_data = nil
	self.stage_data = nil

	-- 경계도 상태
	self.alert_state = {
		-- 기본 상태 (경계도 없음)
		idle = 0,
		-- 발각 상태
		detected = 1
	}

	self.current_alert_state = self.alert_state.idle

	-- 경계도 상태 타이머
	self.alert_state_timer = 0

	-- 테러리스트 상태 테이블
	self.terrorist_infos = {}

	-- 경계 상태 강제종료 존 이름 테이블
	self.alert_quit_zone_names = {}

	-- 패트롤 이벤트 시 체크를 위한 필드 내의 전체 그리드 테이블
	self.camera_grid_names = {}

	-- 현재 카메라 그리드 정보
	self.current_camera_grid_info = nil

	-- 카메라 그리드 별 몬스터 그룹 정보
	self.camera_grid_monster_groups = {}

	-- 경계도 표시 UI
	self.alert_gauge_ui = nil

	-- 코루틴 강제 종료 플래그
	self.stop_coroutine = false

	-- 마커 이름
	self.super_terrorist_reset_marker_name = 'reset_super_terrorist'

	-- 리소스 로드
	self.res_holder = nil

	-- Exclusive 이벤트 키
	self.exclusive_event_key = 'detected_by_terrorist'

	-- 커스텀 이벤트
	self.eliminated_monster_by_chandelier_event = 'eliminated_monster_by_chandelier'
	self.recovert_monster_at_chandelier_event = 'recover_monster_at_chandelier'

	-- 오브젝트 풀
	self.custom_sprite_preset = 'custom_sprite'
	self.hit_projectile_preset = "FX_hit_projectile"
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_field_object_revived_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	-- 기본 상수 설정
	local constants = require('stageeventcontrollers/LilithTowerMetalGearSolidConstants')
	self.common_data = constants['common']
	self.stage_data = constants[stage.Name]

	local alert_quit_zone_names_data = self.stage_data['alert_quit_zone_names']

	for i = 1, #alert_quit_zone_names_data do
		table.insert(self.alert_quit_zone_names, alert_quit_zone_names_data[i])
	end

	local camera_grid_names_data = self.stage_data['camera_resize_grid_names']
	local camera_grid_monster_groups_data = self.stage_data['camera_grid_event_groups']

	for i = 0, field.CameraGrids.Count - 1 do
		local is_patrol = false
		local cur_grid = field.CameraGrids[i]

		for j = 1, #camera_grid_names_data do
			if cur_grid.name == camera_grid_names_data[j] then
				local cur_monster_group

				if #camera_grid_names_data > 0 then
					cur_monster_group = camera_grid_monster_groups_data[j]
				else
					cur_monster_group = nil
				end

				self.camera_grid_names[cur_grid.name] = {
					is_patrol = true,
					monster_group_name = cur_monster_group
				}

				is_patrol = true
			end
		end

		if not is_patrol then
			self.camera_grid_names[cur_grid.name] = {
				is_patrol = false,
				monster_group_name = nil
			}
		end
	end

	-- 3스테이지 메인 퀘스트에서 샹들리에를 떨어뜨린 후라면 해당 그리드는 Patrol 몬스터들이 없는 것으로 처리함
	local main_quest_id = 258
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

	if stage.Name == 'lilithtower_1_3' and quest_progress.InnerProgress > 9 then
		self.camera_grid_names['20'].is_patrol = false
	end

	-- 테러리스트 설정
	-- 순찰형
	for i = 1, self.stage_data['patrol_terrorist_num'] do
		local cur_name = self.stage_data['patrol_terrorist_name']..i
		local cur_terrorist = get_character(cur_name)

		self.terrorist_infos[cur_name] = {
			character = cur_terrorist,
			monster_timer = 0,
			is_battle = false,
			activate = true,
			is_super = false
		}

		-- 순찰형 FieldObjectController에 기본 설정
		cur_terrorist.FieldObjectController.PatrolSight = self.common_data['terrorist_sight_distance_idle']
		cur_terrorist.FieldObjectController.PatrolAngle = self.common_data['terrorist_sight_angle_idle']
		cur_terrorist.FieldObjectController.PuzzledChangeDirectionDelay = self.common_data['terrorist_puzzled_change_direction_delay']
		cur_terrorist.FieldObjectController.ReturnedSpeed = self.common_data['terrorist_returned_speed']
		cur_terrorist.FieldObjectController.BattleTalkStringKey = 'lilithtower_terrorist_notice'

		stage.BattleManager:AddToNoAssassination(cur_terrorist)
	end

	-- 강화형
	for i = 1, self.stage_data['super_terrorist_num'] do
		local cur_name = self.stage_data['super_terrorist_name']..i
		local cur_terrorist = get_character(cur_name)

		self.terrorist_infos[cur_name] = {
			character = cur_terrorist,
			monster_timer = 0,
			is_battle = false,
			activate = true,
			is_super = true
		}

		-- 강화형 FieldObjectController에 기본 설정
		cur_terrorist.FieldObjectController.PatrolSight = self.common_data['terrorist_sight_distance_idle']
		cur_terrorist.FieldObjectController.PatrolAngle = self.common_data['terrorist_sight_angle_idle']
		cur_terrorist.FieldObjectController.PuzzledChangeDirectionDelay = self.common_data['terrorist_puzzled_change_direction_delay']
		cur_terrorist.FieldObjectController.ReturnedSpeed = self.common_data['terrorist_returned_speed']
		cur_terrorist.FieldObjectController.BattleTalkStringKey = 'lilithtower_terrorist_notice'

		stage.BattleManager:AddToNoAssassination(cur_terrorist)
	end

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate(self.custom_sprite_preset)
	unity_object_pool.GetOrCreate(self.hit_projectile_preset)

	yield_return(unity_object_pool, 'WaitAll')

	self.res_holder = CS.Foundations.ResourceHolder()

	-- 경계도 UI 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/v2_22_lilithtower/ui', 'ui_alert_gauge', function(prefab)
				local alert_ui_obj = CS.NGUITools.AddChild(field_ui_manager.Transform.gameObject, prefab)
				self.alert_gauge_ui = alert_ui_obj.transform:GetComponent(typeof(CS.Oak.UI.FieldUIAlertGauge))
			end)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(e)
	self.alert_gauge_ui:Hide()
end

function local_class:on_stage_start_event(e)
	-- 비활성화된 테러리스트들은 ActiveState 변경하고 처리하지 않음
	for _, cur_info in pairs(self.terrorist_infos) do
		if cur_info.character ~= nil and cur_info.character.ActiveState ~= active_state('enabled') then
			cur_info.activate = false
		end
	end

	-- 전투 상태가 된 몬스터 처리
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.control_monster, self))
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
		for _, cur_zone_name in pairs(self.alert_quit_zone_names) do
			if e.Zone.Name == cur_zone_name then
				self:change_alert_state(self.alert_state.idle)

				break
			end
		end
	end
end

function local_class:on_camera_grid_enter_event(e)
	self.current_camera_grid_info = e.CameraGrid

	-- 이벤트 중일 때는 작동하지 않음
	if self.camera_grid_names[e.CameraGrid.name].is_patrol then
		self:show_warning_ui()

		camera_util.resize_to(5, 0.5, true)
	else
		self.alert_gauge_ui:Hide()

		camera_util.resize_to_default(0.5, true)
	end
end

function local_class:on_damage_event(e)
	for _, cur_info in pairs(self.terrorist_infos) do
		if cur_info.character ~= nil and lua_helper.reference_equals(e.Info.sender, get_party_leader()) and
				lua_helper.reference_equals(e.Info.target, cur_info.character) then
			-- 전투 중이 아니면 ? 표시
			if stage.BattleManager:GetBattleFor(get_party_leader()) == nil then
				CS.Oak.NoticeIcon.SetPuzzled(cur_info.character)
			end

			-- 데미지 입히면 경계 타이머 리셋
			self.alert_state_timer = 0
		end

		-- 슈퍼 테러리스트는 방어무시 데미지에 죽지 않도록 받은 데미지만큼 힐
		if (e.Info.type == CS.Oak.DamageType.Trap | CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick) or
			CS.Oak.DamageType.IgnoreDefense or CS.Oak.DamageType.IgnoreOptions then
			if cur_info.is_super then
				local heal_info = CS.Oak.HealInfo()
				heal_info.sender = cur_info.character
				heal_info.target = cur_info.character
				heal_info.heal = e.Info.damage
				heal_info.skipEffect = true

				command_util.execute_heal(heal_info)
			end
		end
	end
end

function local_class:on_field_object_revived_event(e)
	if self.camera_grid_names[self.current_camera_grid_info.name].is_patrol and
			lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
		camera_util.resize_to(5, 0.5, true)
	end

	-- 부활 후 테러리스트에 발각되지 않는 유예기간 줌
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_user_cannot_detected, self))
end

function local_class:on_field_object_destroyed_event(e)
	for _, cur_info in pairs(self.terrorist_infos) do
		if cur_info.character ~= nil and lua_helper.reference_equals(e.FieldObject, cur_info.character) then
			-- 테러리스트 죽였으면 경계 타이머 리셋
			self.alert_state_timer = 0
		end
	end
end

function local_class:on_battle_start_event(e)
	local current_battle_monsters = e.StartedBattle.AllCharacters
	local is_normal_battle = true

	for _, cur_info in pairs(self.terrorist_infos) do
		if cur_info.character ~= nil and current_battle_monsters:Contains(cur_info.character) then
			if is_normal_battle then
				is_normal_battle = false
			end

			if not cur_info.is_battle then
				cur_info.is_battle = true
			end
		end
	end

	if is_normal_battle then
		-- 일반 몬스터와 전투 시에 경계 레벨 리셋
		self:change_alert_state(self.alert_state.idle)
	else
		-- 테러리스트들과 전투 시 경계 레벨 상승
		self:change_alert_state(self.alert_state.detected)
	end
end

function local_class:on_battle_group_eliminated_event(e)
	self:change_alert_state(self.alert_state.idle)

	self.alert_gauge_ui:Hide()

	camera_util.resize_to_default(0.5)

	for _, cur_info in pairs(self.camera_grid_names) do
		if e.BattleGroupName == cur_info.monster_group_name then
			cur_info.is_patrol = false
		end
	end
end

function local_class:on_game_over_event(e)
	-- 게임 오버 시 경계 레벨 리셋
	self:change_alert_state(self.alert_state.idle)
end

function local_class:on_custom_stage_event(e)
	-- 메인 퀘스트 상태와 관계없이 강제로 켜고 꺼준다
	if e:GetParamAt(0) == self.eliminated_monster_by_chandelier_event then
		self.camera_grid_names['20'].is_patrol = false
	elseif e:GetParamAt(0) == self.recovert_monster_at_chandelier_event then
		self:show_warning_ui()

		camera_util.resize_to(5, 0.5, true)

		self.camera_grid_names['20'].is_patrol = true
	end

	return false
end

-- 매 프레임 몬스터로 변한 테러리스트들을 체크해서 플레이어와 일정 거리 이상 멀어지면 제자리에서 대기하는 AI로 변경
function local_class:control_monster()
	while not self.stop_coroutine do
		-- 모든 전투 중인 몬스터들이 플레이어를 보지 못하는 상태면 전투 종료
		local cannot_see_player_num = 0
		local battle_monsters = {}
		local timers = {}

		for _, cur_info in pairs(self.terrorist_infos) do
			if cur_info.is_battle then
				table.insert(battle_monsters, cur_info)

				-- Monster Timer 조절
				if cur_info.character ~= nil and not self:is_in_sight(cur_info.character, get_party_leader(),
						self.common_data['terrorist_sight_distance_detected'],
						self.common_data['terrorist_sight_angle_detected']) then

					if cur_info.monster_timer < self.common_data['terrorist_keep_monster_delay'] then
						cur_info.monster_timer = cur_info.monster_timer + unity_class.time.deltaTime
					else
						cannot_see_player_num = cannot_see_player_num + 1
					end
				else
					cur_info.monster_timer = 0
				end

				table.insert(timers, cur_info.monster_timer)
			end
		end

		if cannot_see_player_num > 0 and cannot_see_player_num == #battle_monsters then
			for _, cur_info in pairs(battle_monsters) do
				if cur_info.character ~= nil then
					CS.Oak.NoticeIcon.SetPuzzled(cur_info.character)

					message_system:Publish(CS.Oak.MonsterGiveUpEvent.Create(cur_info.character, nil))

					message_system:Send(cur_info.character.FieldObjectController,
							CS.Oak.MonsterGiveUpEvent.Create(cur_info.character, nil))

					cur_info.is_battle = false
					cur_info.monster_timer = 0
				end
			end
		end

		-- UI 게이지 감소
		if #timers > 0 and self.current_alert_state == self.alert_state.detected then
			-- UI 게이지 감소 수치는 몬스터들 중 가장 타이머 수치가 낮은 것 기준 (낮을 수록 남은 시간이 오래 걸리는 것)
			local smallest_timer = 999
			for _, cur_timer in pairs(timers) do
				if smallest_timer > cur_timer then
					smallest_timer = cur_timer
				end
			end

			self.alert_gauge_ui:UpdateGauge((self.common_data['terrorist_keep_monster_delay'] - smallest_timer) /
					self.common_data['terrorist_keep_monster_delay'])
		end

		coroutine.yield(nil)
	end
end

-- Alert State 변경
function local_class:change_alert_state(alert_state)
	if self.current_alert_state ~= alert_state then
		self.current_alert_state = alert_state
	else
		return
	end

	-- Alert State가 Idle로 변경됨
	if alert_state == self.alert_state.idle then
		for _, cur_info in pairs(self.terrorist_infos) do
			if cur_info.character ~= nil then
				-- 전투에 남아 있는 경우 종료
				if stage.BattleManager:GetBattleFor(cur_info.character) ~= nil then
					message_system:Publish(CS.Oak.MonsterGiveUpEvent.Create(cur_info.character, nil))
					message_system:Send(cur_info.character.FieldObjectController,
							CS.Oak.MonsterGiveUpEvent.Create(cur_info.character, nil))
				end

				-- 배틀액션 중단
				cur_info.character.CharacterBehaviour:CancelAllBattleActions()

				-- 제자리 돌아가게 설정
				cur_info.character:OnEvent(CS.Oak.ReturnToPatrolEvent.Instance)

				-- 이동속도 복구
				if cur_info.character ~= nil then
					buff_manager:RemoveBuff(
							cur_info.character, CS.Oak.EquipmentSlot.None, cur_info.character, 'speed_down_persistent')
				end
			end
		end

		self.alert_gauge_ui:UpdateGauge(0)
		self.alert_gauge_ui:SetWarning()

		-- 모든 전투 강제종료
		stage.BattleManager:ForceEndBattles()

		-- 남아 있는 프로젝타일 제거
		stage.ProjectileManager:ClearProjectiles()

		-- ExclusiveQuestEndEvent Publish
		message_system:PublishSync(CS.Oak.ExclusiveQuestEndEvent.Create(self.exclusive_event_key, false))

	-- Alert State가 Detected로 변경됨
	elseif alert_state == self.alert_state.detected then
		self.alert_gauge_ui:Show()
		self.alert_gauge_ui:SetDanger()

		-- ExclusiveQuestStartEvent Publish
		message_system:PublishSync(CS.Oak.ExclusiveQuestStartEvent.Create(self.exclusive_event_key, false))

		coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.check_alert_detected, self))
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.detected_tint, self))
	end
end

-- 경계 레벨 Detected 상태에서 매 프레임 돌면서 일정 시간이 지나서 경계 레벨이 내려가는지 확인하는 코루틴
function local_class:check_alert_detected()
	self.alert_state_timer = 0

	local past_camera_grid_info = self.current_camera_grid_info

	while self.current_alert_state == self.alert_state.detected do
		-- 전투 중인 적이 없으면 while문 탈출
		local is_battle = false

		for _, cur_info in pairs(self.terrorist_infos) do
			if cur_info.is_battle then
				is_battle = true

				break
			end
		end

		if not is_battle then
			break
		end

		-- 카메라 그리드가 변경되었으면 while문 탈출
		if past_camera_grid_info.name ~= self.current_camera_grid_info.name then
			break
		end

		self.alert_state_timer = self.alert_state_timer + unity_class.time.deltaTime

		coroutine.yield(nil)
	end

	-- 카메라 그리드가 변경된 경우 그리드 이동 끝날 때까지 대기
	if past_camera_grid_info.name ~= self.current_camera_grid_info.name then
		wait_for_unscaled_sec(0.65)
	end

	-- 중간에 경계 상태 변경이 없을 경우 여기서 변경 진행
	if self.current_alert_state == self.alert_state.detected then
		self:change_alert_state(self.alert_state.idle)
	end
end

-- A의 시야에 B가 들어왔는지 확인, y축은 무시함
function local_class:is_in_sight(fo, target, distance, angle)
	local full_diff = target.Bounds.center - fo.Bounds.center
	local diff = target.Bounds.center - fo.Bounds.center

	if diff.magnitude > distance then
		return false
	end

	diff.y = 0

	if unity_class.vector3.Angle(diff.normalized, direction_util.to_vector3(fo.Direction)) > angle / 2 then
		return false
	end

	if field:IsAnythingBlockingWithoutBounds(
			CS.UnityEngine.Bounds(fo.Bounds.center, vector(0.05, 0.05, 0.05)),
			CS.Oak.EntityGroups.Obstacle | CS.Oak.EntityGroups.Neutral0, vector_util.get_x0z(full_diff)) then
		return false
	end

	return true
end

-- 경계 레벨이 Detected일 때, 화면 붉게 점멸하는 이벤트
function local_class:detected_tint()
	local is_tint = false
	local tint_duration = 0.5
	local timer = tint_duration
	local tint_color = unity_color({ 1, 0, 0, 1 })
	local tint_key = 'detected'

	while self.current_alert_state == self.alert_state.detected do
		timer = timer + unity_class.time.deltaTime

		if timer >= tint_duration then
			timer = 0

			if not is_tint then
				is_tint = true

				field:Tint(tint_key, tint_color, tint_duration)
			else
				is_tint = false

				field:RemoveTint(tint_key, tint_duration)
			end
		end

		coroutine.yield(nil)
	end

	if is_tint then
		field:RemoveTint(tint_key, tint_duration / 3)
	end
end

-- 카메라에 해당 위치 좌표가 보이는지 리턴
function local_class:is_pos_in_camera(pos)
	local cam_half_height = stage_camera.Size
	local cam_half_width = stage_camera.HalfWidth
	local camera_pos = stage_camera.LookAtPosition

	if math.abs(camera_pos.x - pos.x) > cam_half_width + 0.7 or
			-- 카메라의 y값도 보정해서 계산
			math.abs(camera_pos.y / 1.414 + camera_pos.z - pos.z) > cam_half_height + 0.5 then
		return false
	end

	return true
end

-- Warning UI 표시
function local_class:show_warning_ui()
	self.alert_gauge_ui:SetWarning()
	self.alert_gauge_ui:UpdateGauge(0)
	self.alert_gauge_ui:Show()
end

-- 플레이어 부활 후에 일정 시간 동안 테러리스트에 걸리지 않도록 설정
function local_class:set_user_cannot_detected()
	get_party_leader().EntityGroup = CS.Oak.EntityGroups.Neutral0

	-- 다시 죽으면 코루틴 여러 개가 돌 수 있으니 방지
	character_util.set_immortal(get_party_leader(), true)

	local timer = 0
	local duration = 3

	while timer < duration do
		timer = timer + unity_class.time.deltaTime

		coroutine.yield(nil)
	end

	get_party_leader().EntityGroup = CS.Oak.EntityGroups.Player0

	character_util.set_immortal(get_party_leader(), false)
end

function local_class:dispose()
	self.stop_coroutine = true

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.common_data = nil
	self.stage_data = nil

	self.terrorist_infos = nil
	self.alert_quit_zone_names = nil

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
		self.res_holder = nil
	end

	self.alert_gauge_ui = nil

	self.camera_grid_names = nil
	self.current_camera_grid_info = nil

	self.camera_grid_monster_groups = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
