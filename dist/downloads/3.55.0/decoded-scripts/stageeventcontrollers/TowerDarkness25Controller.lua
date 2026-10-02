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
	-- -- battle_group_name : 해당 스테이지 몬스터 그룹 이름
	-- -- wave_interval : 웨이브별 간격 (초)
	-- -- last_wave : 마지막 웨이브 번호, 0-based index. 총 웨이브 갯수는 value + 1
	-- -- enemy_limit : Zone내 들어올 수 있는 몬스터 최대 숫자 + 1 (예 13이면 12마리 까지 존재 가능, 넘어가면 게임 오버)
	-- -- is_repeat_wave : 웨이브가 무한 반복될경우 true, 아닐 경우 false
	self.stage_battle_info = {
		tower_light_25 = {
			narration_info = 'elemental_light_1_narration',
			battle_group_name = 'wave',
			wave_interval = 8,
			last_wave = 3,
			enemy_limit = 13,
			is_repeat_wave = false
		},
		tower_darkness_25 = {
			narration_info = 'tower_darkness_elite_1_narration',
			battle_group_name = 'battle1',
			wave_interval = 10,
			last_wave = 2,
			enemy_limit = 13,
			is_repeat_wave = true
		}
	}

	self.wave_cleared = false

	self.get_custom_sprite = function()
		return unity_object_pool.GetOrCreate('custom_sprite')
	end

	self.pooled_sprite = nil

	self.monster_init_pos = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')

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
	self.battle_group = stage.BattleManager:GetBattleGroup(self.stage_battle_info[stage.Name].battle_group_name)
	self.battle_group.SpawnNextWaveAutomatically = false

	self.monster_init_pos = { }
	local monsters = self.battle_group:GetMonsters()
	for _, monster in pairs(monsters) do
		self.monster_init_pos[monster] = monster.Position
		-- 무한 반복 웨이브에서 몬스터 PatrolAI 안꺼주면 BattleInstance가 여러개 생성됨
		-- 몬스터 Notice 무한 반복 웨이브 맵에선 수동 관리함.
		if self.stage_battle_info[stage.Name].is_repeat_wave then
			monster.FieldObjectController.PatrolAI = CS.Oak.PatrolAI.None
		end
	end
	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.stage_battle_info[stage.Name].battle_group_name) and self.current_progress == self.progress.none then
		self.current_progress = self.progress.playing
		self:start_enemy_count()
	end
	return false
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		if lua_helper.type_compare(e.FieldObject.FieldObjectController, CS.Oak.MonsterCharacterController) then
			self:get_monster_count()
			if self.current_progress == self.progress.playing then
				self:update_count_ui(user_party.Leader, self.current_enemy_count)
			end
			local boss = get_character('boss')
			-- 무한 반복웨이브 맵이면 보스가 죽을때만 클리어 처리
			if lua_helper.reference_equals(boss, e.FieldObject) and self.stage_battle_info[stage.Name].is_repeat_wave then
				self:kill_all_monsters()
				self.current_progress = self.progress.cleared
			end
			return true
		end
	elseif lua_helper.type_compare(e, CS.Oak.BattleGroupEliminatedEvent) then
		if e.BattleGroupName == self.stage_battle_info[stage.Name].battle_group_name then
			-- 무한 반복웨이브 맵이면 보스가 죽을때만 클리어 처리
			if not self.stage_battle_info[stage.Name].is_repeat_wave then
				self.current_progress = self.progress.cleared
				return true
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
	elseif lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		sp_util.play_normal_screenplay(self.on_stage_start_event, self)
		return true
	end
	return false
end

function local_class:on_stage_start_event()
	-- 몬스터들의 수가 X마리가 넘으면 게임 오버!
	field_ui_util.show_narration_async({ key = self.stage_battle_info[stage.Name].narration_info })
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

function local_class:start_enemy_count()
	self:attach_count_ui(user_party.Leader, 0)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attach_image_ui, self, user_party.Leader))
	self.current_progress = self.progress.playing
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enemy_add_timer, self))
end

-- 특정 웨이브에 속한 몬스터들중 죽어있던 애들의 위치 초기화
function local_class:reset_monster_pos(wave_num)
	local monsters = self.battle_group:GetMonsters(wave_num)

	for _, monster in pairs(monsters) do
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
	local monsters = self.battle_group:GetMonsters()
	local tmp = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap | CS.Oak.DamageType.Death
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = tmp
	damage_info.notMortal = false

	for _, monster in pairs(monsters) do
		damage_info.sender = monster
		damage_info.target = monster
		damage_info.damage = monster.FieldObjectStatsBehaviour.MaxHP * 2

		command_util.execute_damage(damage_info)
	end
end

-- 무한 반복 웨이브 일 경우 혹시 모를 후처리를 위해 만약 리셋이 되었다면 true를 리턴함
function local_class:spawn_enemy_wave()
	local battle_group_name_str = self.stage_battle_info[stage.Name].battle_group_name

	if self.stage_battle_info[stage.Name].is_repeat_wave then
		if self.battle_group.CurrentWave == self.stage_battle_info[stage.Name].last_wave then
			-- 회복되는거 안보이게 위치 999,999로 보내줌.
			self:send_monster_far()
			-- 맨 마지막 웨이브니까 배틀그룹 리셋(죽어있는 애들만 힐, BattleGroup.cs:514-565 참조)
			message_system:PublishSync(CS.Oak.BattleGroupResetEvent.Create(battle_group_name_str, true))
			-- 위치 리셋
			self:reset_monster_pos(0)
			message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(battle_group_name_str))
			return true
		else
			-- 다음 웨이브 몬스터 위치 리셋
			self:reset_monster_pos(self.battle_group.CurrentWave + 1)
			message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(battle_group_name_str))
			return false
		end
	else
		message_system:Publish(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(battle_group_name_str))
		return false
	end
end

function local_class:get_monster_count()
	local count = 0
	local pool = self.battle_group:GetMonsters()
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
		self:get_monster_count()
		self:update_count_ui(user_party.Leader, self.current_enemy_count)
		self:update_image_ui(user_party.Leader)

		if timer > self.stage_battle_info[stage.Name].wave_interval * wave then
			-- CS.UnityEngine.Debug.Log('spawned wave : '..(wave - 1))
			self:spawn_enemy_wave()
			wave = wave + 1
		end
		timer = game_timer.Elapsed
		coroutine.yield(nil)
	end
	if self.current_progress == self.progress.failed then
		message_system:PublishSync(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))

		self:custom_game_over()
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

function local_class:custom_game_over()
	-- CS.UnityEngine.Debug.Log('user_party_leader pos before : '..(user_party.Leader.Position:ToString()))

	character_util.set_direction(user_party.Leader, 'right')
	character_util.set_anim_and_emotion(user_party.Leader, {name = 'seat'}, {name = 'damaged'})

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
end

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
	local invader_sprite = self.pooled_sprite.transform:GetComponent(typeof(CS.CustomSprite))
	invader_sprite.transform.localRotation = unity_class.quaternion.Euler(45, 0, 0)
	invader_sprite.transform.localScale = unity_class.vector3.one * 0.5
	invader_sprite.Atlas = custom_atlas

	invader_sprite.SpriteName = 'emoticon_bubble_invader.png'
	invader_sprite:Rebuild()
end

function local_class:update_image_ui(target)
	-- local pos = target.Bounds.center
	if self.pooled_sprite ~= nil then
		-- self.pooled_sprite.transform.localPosition = vector(pos.x - 0.25, pos.y + target.Bounds.size.y + 1, pos.z - 0.5)
		return
	end
end

function local_class:detach_image_ui()
	if self.pooled_sprite ~= nil then
		self.pooled_sprite:Dispose()
		self.pooled_sprite = nil
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
