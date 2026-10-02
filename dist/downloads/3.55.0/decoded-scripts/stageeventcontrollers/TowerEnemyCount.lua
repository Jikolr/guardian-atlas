local local_class = newclass('TowerEnemyCount')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3,
		failed = 4
	}
	self.current_progress = self.progress.none

	self.current_enemy_count = 0

	-- 스테이지별 웨이브에 필요한 정보를 담고 있는 구조체
	-- Key : 스테이지 이름
	-- Value : 필요 정보들의 테이블
	-- -- narration_info : 스테이지 입장시 출력될 몬스터 제한 갯수 나레이션 스트링 키값
	-- -- battle_group_names : 해당 스테이지 몬스터 그룹 이름
	-- -- wave_interval : 웨이브별 간격 (초)
	-- -- last_wave : 마지막 웨이브 번호, 0-based index. 총 웨이브 갯수는 value + 1
	-- -- enemy_limit : Zone내 들어올 수 있는 몬스터 최대 숫자 + 1 (예 13이면 12마리 까지 존재 가능, 넘어가면 게임 오버)
	-- -- is_repeat_wave : 웨이브가 무한 반복될경우 true, 아닐 경우 false
	self.stage_battle_info = {
		tower_light_25 = {
			narration_info = 'elemental_light_1_narration',
			battle_group_names = {'wave'},
			wave_interval = 12,
			last_wave = 3,
			enemy_limit = 13,
			is_repeat_wave = false,
			forbid_combination = false
		},
		tower_darkness_25 = {
			narration_info = 'tower_darkness_elite_1_narration',
			battle_group_names = {'battle1'},
			wave_interval = 12,
			last_wave = 2,
			enemy_limit = 13,
			is_repeat_wave = true,
			forbid_combination = false
		},
		tower_earth_25 = {
			narration_info = 'elemental_earth_1_narration',
			battle_group_names = {'wave'},
			wave_interval = 12,
			last_wave = 4,
			enemy_limit = 13,
			is_repeat_wave = false,
			forbid_combination = true
		},
		tower_fire_25 = {
			narration_info = 'tower_fire_elite_3_narration',
			battle_group_names = {'battle1', 'battle2'},
			wave_interval = 14,
			last_wave = 2,
			enemy_limit = 8,
			is_repeat_wave = false,
			forbid_combination = true
		},
		tower_ice_25 = {
			narration_info = 'tower_ice_elite_3_narration',
			battle_group_names = {'boss'},
			wave_interval = 10,
			last_wave = 4,
			enemy_limit = 12,
			is_repeat_wave = false,
			forbid_combination = true
		},
		tower_none_25 = {
			narration_info = 'tower_none_elite_3_narration',
			battle_group_names = {'battle_1'},
			wave_interval = 11,
			last_wave = 4,
			enemy_limit = 12,
			is_repeat_wave = false,
			forbid_combination = true
		},
		tower_120 = {
			narration_info = 'tower_120_narration',
			battle_group_names = {'battle_1'},
			wave_interval = 11,
			last_wave = 3,
			enemy_limit = 8,
			is_repeat_wave = true,
			forbid_combination = false
		},
	}

	self.wave_cleared = false
	self.num_battle_zone_cleared = 0

	self.get_custom_sprite = function()
		return unity_object_pool.GetOrCreate('custom_sprite')
	end

	self.pooled_sprite = nil
	self.timer = 0

	self.monster_init_pos = nil
	self.entered_battle_zone_idx = -1
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')

	self.get_custom_sprite()

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))


	self.monster_init_pos = nil

	self.custom_event_listener = nil
	self.cs_controller = nil

	self:detach_count_ui()
	self:detach_image_ui()
end

function local_class:on_stage_loaded_event(_)
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')

	self.battle_groups = {}
	self.monster_init_pos = {}

	local battle_manager = stage.BattleManager
	local num_battle_groups = #self.stage_battle_info[stage.Name].battle_group_names
	for i = 1, num_battle_groups do
		self.battle_groups[i] = battle_manager:GetBattleGroup(self.stage_battle_info[stage.Name].battle_group_names[i])
		self.battle_groups[i].SpawnNextWaveAutomatically = false
	end

	local monsters = {}
	for i = 1, num_battle_groups do
		monsters[i] = self.battle_groups[i]:GetMonsters()
		local monster_count = monsters[i].Count

		for j = 1, monster_count - 1 do
			local monster = monsters[i][j]
			self.monster_init_pos[monster] = monster.Position
			-- 무한 반복 웨이브에서 몬스터 PatrolAI 안꺼주면 BattleInstance가 여러개 생성됨
			-- 몬스터 Notice 무한 반복 웨이브 맵에선 수동 관리함.
			if self.stage_battle_info[stage.Name].is_repeat_wave then
				monster.FieldObjectController.PatrolAI = CS.Oak.PatrolAI.None
			end
		end
	end
end

function local_class:on_zone_enter_event(e)
	for i = 1, #self.stage_battle_info[stage.Name].battle_group_names do
		if type_util.is_zone_full_enter(e, user_party.Leader, self.stage_battle_info[stage.Name].battle_group_names[i]) then
			if self.entered_battle_zone_idx == i then break end

			self.entered_battle_zone_idx = i

			if self.current_progress == self.progress.none then
				self.current_progress = self.progress.playing
				self:start_enemy_count(i)
			end

			-- 전투는 한번에 한 곳에서만 발생하니, 반복문 탈출
			break
		end
	end

	return false
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		if lua_helper.type_compare(e.FieldObject.FieldObjectController, CS.Oak.MonsterCharacterController) then

			self:get_monster_count(self.entered_battle_zone_idx)
			if self.current_progress == self.progress.playing then
				self:update_count_ui(user_party.Leader, self.current_enemy_count)
			end
			local boss = get_character('boss')
			-- 무한 반복웨이브 맵이면 보스가 죽을때만 클리어 처리
			if lua_helper.reference_equals(boss, e.FieldObject) and self.stage_battle_info[stage.Name].is_repeat_wave then
				self:kill_all_monsters()
			end
			return true
		end
	elseif lua_helper.type_compare(e, CS.Oak.BattleGroupEliminatedEvent) then
		for i = 1, #self.stage_battle_info[stage.Name].battle_group_names do
			if e.BattleGroupName == self.stage_battle_info[stage.Name].battle_group_names[i] then
				self.num_battle_zone_cleared = self.num_battle_zone_cleared + 1
				-- 무한 반복웨이브 맵이면 보스가 죽을때만 클리어 처리

				if self.num_battle_zone_cleared == #self.stage_battle_info[stage.Name].battle_group_names then
					self.current_progress = self.progress.cleared
				else
					self.current_progress = self.progress.none
				end
			end
		end

	elseif lua_helper.type_compare(e, CS.Oak.GameOverEvent) then
		message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
		if self.current_progress == self.progress.playing then
			self:set_character_far()
			self.current_progress = self.progress.failed
		else
			-- 보스 죽이고 나서 화약통으로 자살할 경우 처리
			self:custom_game_over()
		end
		-- message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
		return true
	end

	return false
end

function local_class:on_stage_start_event()
	-- 몬스터들의 수가 X마리가 넘으면 게임 오버!
	local show_narration = function()
		field_ui_manager:Hide()
		field_ui_util.show_narration_async(		{ key = self.stage_battle_info[stage.Name].narration_info })
		field_ui_manager:Show()
	end

	local current_stage_info = self.stage_battle_info[stage.Name]
	if current_stage_info.narration_info ~= nil then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(show_narration))
	end

	if current_stage_info.forbid_combination then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.remove_combination_button, self))
	end
end

function local_class:remove_combination_button()
	while (self.current_progress ~= self.progress.cleared) do
		field_ui_manager:RemoveUI(user_party_leader, CS.Oak.FieldUiType.TeamCombinationButton)
		coroutine.yield(nil)
	end
end

-- 화약통 데미지 증폭
function local_class:on_damage_event(e)
	if lua_helper.type_compare(e, CS.Oak.DamageEvent) then
		local tmp = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap
		if lua_helper.reference_equals(e.Info.type, tmp) then
			if lua_helper.type_compare(e.Info.sender.FieldObjectBehaviour, CS.Oak.BarrelFieldObjectBehaviour) or
					lua_helper.type_compare(e.Info.sender.FieldObjectBehaviour, CS.Oak.BombFieldObjectBehaviour) then
				if not lua_helper.reference_equals(e.Info.target, user_party_leader) then
					local damage_info = CS.Oak.DamageInfo()
					local c = 0.105 -- 정확히 0.1을 더해주면 5방 만에 죽지 않고 Hp가 1~5 정도 남음
					damage_info.type = tmp
					damage_info.sender = e.Info.target
					damage_info.target = e.Info.target
					damage_info.damage = math.floor(e.Info.target.FieldObjectStatsBehaviour.MaxHP * c)
					damage_info.notMortal = false

					command_util.execute_damage(damage_info)
				end
			end
		end
	end
end

function local_class:start_enemy_count(zone_idx)
	self:attach_count_ui(user_party.Leader, 0)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attach_image_ui, self, user_party.Leader))
	self.current_progress = self.progress.playing
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enemy_add_timer, self))
end

-- 특정 웨이브에 속한 몬스터들중 죽어있던 애들의 위치 초기화
function local_class:reset_monster_pos(battle_group, wave_num)
	local monsters = battle_group:GetMonsters(wave_num)

	for i = 0, monsters.Count - 1 do
		local monster = monsters[i]
		if is_unity_null(stage.BattleManager:GetBattleFor(monster)) then
			monster.Position = self.monster_init_pos[monster]

			-- notice로 새로운 BattleInstance생성을 막기 위해 기존 BattleInstance에다 재활성시 몬스터 추가.
			-- BattleManager.cs:644-665 참고
			local thebattle = stage.BattleManager:GetBattleForMyParty()
			thebattle:AddEnemy(monster)

			-- 이벤트 IsPublish안하면 MonsterBattleAIState에서 타겟이 지정안되는 오류 발생
			local cmd = CS.Oak.MonsterNoticeCommand.Create(monster, user_party_leader, CS.Oak.MonsterNoticeLevel.Battle)
			command_util.publish_cmd(monster.Owner, cmd)
		end
	end
end

-- 회복되는거 안보이게 몬스터 999,0,999로 보내줌
function local_class:send_monster_far()
	for monster, init_pos in pairs(self.monster_init_pos) do
		if is_unity_null(stage.BattleManager:GetBattleFor(monster)) then
			monster.Position = vector(999,0,999)
		end
	end
end

function local_class:kill_all_monsters()
	local tmp = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap | CS.Oak.DamageType.Death
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = tmp
	damage_info.notMortal = false

	for i = 1, #self.battle_groups do
		local monsters = self.battle_groups[i]:GetMonsters()

		for j = 0, monsters.Count - 1 do
			local monster = monsters[j]
			damage_info.sender = monster
			damage_info.target = monster
			damage_info.damage = monster.FieldObjectStatsBehaviour.MaxHP * 2

			command_util.execute_damage(damage_info)
		end
	end
end

-- 무한 반복 웨이브 일 경우 혹시 모를 후처리를 위해 만약 리셋이 되었다면 true를 리턴함
function local_class:spawn_enemy_wave(zone_idx)
	local battle_group_name_str = self.stage_battle_info[stage.Name].battle_group_names[zone_idx]

	if self.stage_battle_info[stage.Name].is_repeat_wave then
		if self.battle_groups[zone_idx].CurrentWave == self.stage_battle_info[stage.Name].last_wave then
			-- 회복되는거 안보이게 위치 999,999로 보내줌.
			self:send_monster_far()
			-- 맨 마지막 웨이브니까 배틀그룹 리셋(죽어있는 애들만 힐, BattleGroup.cs:514-565 참조)
			message_system:PublishSync(CS.Oak.BattleGroupResetEvent.Create(battle_group_name_str, true))
			-- 위치 리셋
			self:reset_monster_pos(self.battle_groups[zone_idx],0)
			message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(battle_group_name_str))
			return true
		else
			-- 다음 웨이브 몬스터 위치 리셋
			self:reset_monster_pos(self.battle_groups[zone_idx],self.battle_groups[zone_idx].CurrentWave + 1)
			message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(battle_group_name_str))
			return false
		end
	else
		message_system:Publish(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(battle_group_name_str))
		return false
	end
end

function local_class:get_monster_count(zone_idx)
	local count = 0
	local pool = self.battle_groups[zone_idx]:GetMonsters()

	for i = 0, pool.Count - 1 do
		if pool[i].ActiveState == active_state('enabled') then
			count = count + 1
		end
	end

	self.current_enemy_count = count
	return count
end

function local_class:enemy_add_timer()
	local timer = 0
	local wave = 1
	-- 대충 엄청 길게 하면 됨
	local game_timer = CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.SingleGameTimer,
			36000, nil, CS.Oak.InGameTimer.TimerType.DeltaTime)
	message_system:PublishSync(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, game_timer))

	if self.stage_battle_info[stage.Name].is_repeat_wave then
		-- 무한 웨이브 맵경우 배틀존 입장시 수동으로 Notice관리
		local boss = get_character('boss')
		local cmd = CS.Oak.MonsterNoticeCommand.Create(boss, user_party_leader, CS.Oak.MonsterNoticeLevel.Battle)
		command_util.publish_cmd(boss.Owner, cmd)
	end

	while self.current_progress == self.progress.playing do
		self:get_monster_count(self.entered_battle_zone_idx)
		self:update_count_ui(user_party.Leader, self.current_enemy_count)
		self:update_image_ui(user_party.Leader)

		if timer > self.stage_battle_info[stage.Name].wave_interval * wave then
			-- CS.UnityEngine.Debug.Log('spawned wave : '..(wave - 1))
			--CS.UnityEngine.Debug.Log(timer)
			self:spawn_enemy_wave(self.entered_battle_zone_idx)
			wave = wave + 1
		end
		timer = game_timer.Elapsed
		coroutine.yield(nil)
	end
	if self.current_progress == self.progress.failed then
		message_system:PublishSync(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))

	--	self:custom_game_over()
	else
		if self.stage_battle_info[stage.Name].is_repeat_wave then
			message_system:PublishSync(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))

			user_party_leader.CharacterBehaviour:CancelAllBattleActions()

			stage.BattleManager:ForceEndBattles()

			-- 전투 종료후 열리는 문 이름은 현재는 door_1, door_2 로 고정, 향후 확장성 있게 수정 필요
			message_system:PublishSync(CS.Oak.DoorOpenEvent.Create('door_1'), false)
			message_system:PublishSync(CS.Oak.DoorOpenEvent.Create('door_2'), false)
		end

		self:detach_count_ui()
		self:detach_image_ui()
	end
end

-- 점프 도중 죽으면 y축이 어긋나서 카메라가 제대로 포커스를 못잡음, y축이 0이 되지만 스크린 위치는 그대로 유지하게 projection해서 이동시킴
-- 이 상태로 부활하면 맵 바깥에서 부활할수도 있음. 주의할것.
function local_class:set_character_far()
	local projected_player_pos = CS.ViewportScaler.Instance:WorldToScreenPoint(user_party.Leader.Position)

	local cameray = stage_camera.Camera.transform.position.y

	-- 카메라 각도가 항상 45도이니 카메라의 높이 * 루트2 가 카메라로부터의 y=0까지 거리임
	local tmp1 = CS.ViewportScaler.Instance:ScreenToWorldPoint(vector(projected_player_pos.x,projected_player_pos.y,cameray * math.sqrt(2)))
	user_party.Leader.Position = tmp1
end

--[[function local_class:custom_game_over()
	-- CS.UnityEngine.Debug.Log('user_party_leader pos before : '..(user_party.Leader.Position:ToString()))

	character_util.set_direction(user_party.Leader, CS.Oak.DirectionExtensions.GetSideDirection(user_party_leader.Direction))
	character_util.set_anim_and_emotion(user_party.Leader, {name = 'frustration', loop = false, scale = 0.4}, {name = 'damaged'})

	character_util.set_immortal(user_party_leader, true)
	user_party_leader.CharacterBehaviour:CancelAllBattleActions()

	-- CS.UnityEngine.Debug.Log('user_party_leader pos after : '..(user_party.Leader.Position:ToString()))

	stage.FieldUIManager:Hide()
	party_util.stop_and_disable_control()

	for i = 0, user_party.Count - 1 do
		user_party[i].EntityGroup = CS.Oak.EntityGroups.Enemy;
	end

	stage.BattleManager:ForceEndBattles()

	stage:SetGameOver(CS.Oak.UIGameOver.UIGameOverButtonType.LobbyWithWaypoint, false, false)
end]]

---
--- 머리 위에 뜨는 아이콘 및 적의 수 카운트 UI 관련 코드
---

-- z offset -0.5로 해야지 화약통을 머리 위로 들어도 해당 UI엘레멘트가 안가려짐
function local_class:attach_image_ui(target)
	local res_holder = CS.Foundations.ResourceHolder()

	local custom_atlas

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			res_holder, 'spritesheets/battle', 'battle_custom', function(prefab)
				custom_atlas = prefab.transform:GetComponent(typeof(CS.CustomAtlas))
				custom_atlas:Initialize()
			end)

	-- 인베이더 image의 오프셋은 count의 y축 오프셋 * 0.8배가 적당
	local offset = vector(-0.25, target.Bounds.size.y + 1.6, -0.5)
	self.pooled_sprite = self.get_custom_sprite():Instantiate(target.Bounds.center + offset,
			unity_class.quaternion.identity, target.Transform)
	self.invader_sprite = self.pooled_sprite.transform:GetComponent(typeof(CS.CustomSprite))
	self.invader_sprite.transform.localRotation = unity_class.quaternion.Euler(45, 0, 0)
	self.invader_sprite.transform.localScale = unity_class.vector3.one * 0.5
	self.invader_sprite.Atlas = custom_atlas

	self.invader_sprite.SpriteName = 'emoticon_bubble_invader.png'
	self.invader_sprite:Rebuild()
end

function local_class:update_image_ui(target)
	if self.invader_sprite ~= nil and not self.invader_sprite.gameObject.activeSelf then
		self.invader_sprite.gameObject:SetActive(true)
		local offset = vector(-0.25, target.Bounds.size.y + 1.6, -0.5)
		self.invader_sprite.transform:SetParent(nil);
		self.invader_sprite.transform.position = target.Bounds.center + offset
		self.invader_sprite.transform.localRotation = unity_class.quaternion.Euler(45, 0, 0)
		self.invader_sprite.transform:SetParent(target.transform);
		return
	end
end

function local_class:detach_image_ui()
	if self.pooled_sprite ~= nil then
		self.pooled_sprite:Dispose()
		self.pooled_sprite = nil
	end

	if self.invader_sprite ~= nil then
		self.invader_sprite = nil
	end
end

function local_class:attach_count_ui(target, count)
	local offset = vector(0.25, target.Bounds.size.y + 2, -0.5)
	self.count_ui = unity_object_pool.GetOrCreate('FieldUIDuelBuffState'):Instantiate(target.Position + offset,
			unity_class.quaternion.identity, target.Transform)

	self.count_ui.transform:Find('Offset').gameObject:SetActive(false)

	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = count
end

function local_class:update_count_ui(target, value)
	-- local pos = target.Bounds.center
	-- self.count_ui.transform.localPosition = vector( pos.x + 0.25, pos.y + target.Bounds.size.y + 1, pos.z - 0.5)

	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = value
	if value >= self.stage_battle_info[stage.Name].enemy_limit then
		tmp.color = unity_class.color.red

		-- 게임 오버 이벤트 중첩 방지
		message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))

		local damage_info = CS.Oak.DamageInfo()
		damage_info.sender = user_party.Leader
		damage_info.target = user_party.Leader
		damage_info.direction = direction_util.to_vector3('left')

		-- 점프 도중 몬스터 마리수가 한도 초과해서 게임 오버될경우 점프를 강제 종료하기 위해 DeadCommand 발생
		local cmd = CS.Oak.CharacterDeadCommand.Create(damage_info)
		command_util.publish_cmd(user_party.Leader.Owner, cmd)

		self:set_character_far()
		self.current_progress = self.progress.failed
		--gameover
	elseif value >= self.stage_battle_info[stage.Name].enemy_limit * 0.8 then
		tmp.color = unity_class.color.yellow
		--danger
	else
		tmp.color = unity_class.color.white
		--normal
	end
end

function local_class:detach_count_ui()
	if self.count_ui ~= nil then
		self.count_ui.transform:Find('Offset').gameObject:SetActive(true)
		self.count_ui:Dispose()
		self.count_ui = nil
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
