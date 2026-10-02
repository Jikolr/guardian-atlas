local local_class = newclass('TowerCountDown')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3,
	}
	self.current_progress = self.progress.none

	self.get_custom_sprite = function() return unity_object_pool.GetOrCreate('custom_sprite') end

	self.pooled_sprite = nil
	self.timer_sprite = nil

	-- 게임 타이머 계산용
	self.game_timer = nil
	self.add_timer = 0
	self.timer = 0

	self.wave = 0

	-- 스테이지별 웨이브에 필요한 정보를 담고 있는 구조체
	-- Key : 스테이지 이름
	-- Value : 필요 정보들의 테이블
	-- narration_info : 스테이지 입장시 출력될 몬스터 제한 갯수 나레이션 스트링 키값
	-- battle_group_name : 해당 스테이지 몬스터 그룹 이름
	-- wave_interval : 웨이브별 간격 (초)
	-- last_wave : 마지막 웨이브 번호, 0-based index. 총 웨이브 갯수는 value + 1
	-- last_wave_boss_name : 마지막 웨이브 보스 이름
	self.stage_battle_info = {
		tower_fire_15 = {
			narration_info = 'tower_fire_elite_2_narration',
			battle_group_name = 'wave',
			wave_interval = 15,
			last_wave = 4,
			last_wave_boss_name = 'wave_5_boss'
		}
	}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent), 'on_battle_group_wave_clear_event')

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
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent))

	self.custom_event_listener = nil
	self.cs_controller = nil
	self.game_timer = nil

	self.timer_sprite = nil
	self:detach_count_ui()
	self:detach_timer_ui()
end

function local_class:on_stage_loaded_event(_)
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')
	self.battle_group = stage.BattleManager:GetBattleGroup(self.stage_battle_info[stage.Name].battle_group_name)
	return false
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.stage_battle_info[stage.Name].battle_group_name) and self.current_progress == self.progress.none then
		self.current_progress = self.progress.playing
		self:start_enemy_count()
	end
	return false
end

function local_class:on_stage_start_event(e)
	-- 클리어 조건 안내
	local show_narration = function()
		field_ui_manager:Hide()
		field_ui_util.show_narration_async({ key = self.stage_battle_info[stage.Name].narration_info })
		field_ui_manager:Show()
	end
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(show_narration))
end

function local_class:on_battle_group_wave_clear_event(e)
	-- 웨이브가 끝나기 전에 적을 처치시 타이머에 남은시간 만큼 보정해준다.
	if self.wave - 1 ~= e.CurrentWave then
		return false
	end

	if self.timer < self.stage_battle_info[stage.Name].wave_interval * self.wave then
		self.add_timer = self.add_timer + (self.stage_battle_info[stage.Name].wave_interval * self.wave - self.timer)
		self.timer = self.game_timer.Elapsed + self.add_timer
		self.wave = self.wave + 1
	end

	return true
end

function local_class:on_field_object_destroyed_event(e)
	-- 보스를 처치하였을 경우에는 프로세스 Cleared
	if lua_helper.type_compare(e.FieldObject.FieldObjectController, CS.Oak.MonsterCharacterController) then
		local boss = get_character(self.stage_battle_info[stage.Name].last_wave_boss_name)
		if lua_helper.reference_equals(boss, e.FieldObject) then
			self.current_progress = self.progress.cleared
		end
		return true
	end

	return false
end

-- 기믹 시작
function local_class:start_enemy_count()
	self:attach_count_ui(user_party.Leader, 0)
	-- FIXME: 2.10에 다시 사용
	-- coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attach_timer_ui, self, user_party.Leader))
	self.current_progress = self.progress.playing
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.count_down_timer, self))
end

-- 현재 보이는 모든 몬스터에게 죽을만큼의 데미지를 입힌다.
function local_class:kill_all_monsters()
	local monsters = self.battle_group:GetMonsters()
	local tmp = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap | CS.Oak.DamageType.Death
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = tmp
	damage_info.notMortal = false

	for _, monster in pairs(monsters) do
		if monster.ActiveState == active_state('enabled') then
			-- 몬스터가 데미지를 받을 수 있는 상태가 아닐 수도 있기에 DamagedBehaviour을 MonsterDamagedBehaviour로 강제로 교체
			local damage_type = monster.DamagedBehaviour:GetType()
			if damage_type ~= typeof(CS.Oak.MonsterDamagedBehaviour) then
				monster.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create()
			end
			
			damage_info.sender = monster
			damage_info.target = monster
			damage_info.damage = monster.FieldObjectStatsBehaviour.MaxHP * 2

			command_util.execute_damage(damage_info)
		end
	end
end

-- 시간 마다 다음 웨이브로 넘어가는 기믹
function local_class:count_down_timer()
	self.timer = 0
	self.wave = 1
	self.add_timer = 0

	-- 대충 엄청 길게 하면 됨
	self.game_timer = CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.SingleGameTimer, 36000, nil, CS.Oak.InGameTimer.TimerType.DeltaTime)
	message_system:PublishSync(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, self.game_timer))

	local end_wave_count = self.stage_battle_info[stage.Name].last_wave + 1
	while self.current_progress == self.progress.playing do
		self:update_count_ui(self.stage_battle_info[stage.Name].wave_interval * self.wave - math.floor(self.timer + 0.5))
		-- FIXME: 2.10에 다시 사용
		-- self.update_timer_ui(user_party_leader)

		if self.timer >= self.stage_battle_info[stage.Name].wave_interval * self.wave then
			self:kill_all_monsters()

			self.wave = self.wave + 1
			-- 마지막 웨이브때는 while문 탈출
			if self.wave > end_wave_count then
				self.current_progress = self.progress.cleared
				break
			end
		end

		self.timer = self.game_timer.Elapsed + self.add_timer
		coroutine.yield(nil)
	end

	self:detach_count_ui()
	self:detach_timer_ui()
end

-- 타이머 UI 세팅
function local_class:attach_timer_ui(target)
	local res_holder = CS.Foundations.ResourceHolder()

	local custom_atlas

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
		   res_holder, 'spritesheets/battle', 'battle_custom', function(prefab)
			   custom_atlas = prefab.transform:GetComponent(typeof(CS.CustomAtlas))
			   custom_atlas:Initialize()
		   end)

	-- image의 오프셋은 count의 y축 오프셋 * 0.8배가 적당
	local offset = vector(-0.25, target.Bounds.size.y + 1.6, -0.5)
	self.pooled_sprite = self.get_custom_sprite():Instantiate(target.Bounds.center + offset,
		   unity_class.quaternion.identity, target.Transform)
	self.timer_sprite = self.pooled_sprite.transform:GetComponent(typeof(CS.CustomSprite))
	self.timer_sprite.transform.localRotation = unity_class.quaternion.Euler(45, 0, 0)
	self.timer_sprite.transform.localScale = unity_class.vector3.one * 0.5
	self.timer_sprite.Atlas = custom_atlas

	-- FIXME: 타이머 아이콘 들어가게 되면 추가해주어야 함
	self.timer_sprite.SpriteName = 'emoticon_bubble_tease.png'
	self.timer_sprite:Rebuild()
end

-- 타이머 이미지 위치 갱신
function local_class:update_timer_ui(target)
	if self.timer_sprite ~= nil and not self.timer_sprite.gameObject.activeSelf then
		self.timer_sprite.gameObject:SetActive(true)
		local offset = vector(-0.25, target.Bounds.size.y + 1.6, -0.5)
		self.timer_sprite.transform:SetParent(nil);
		self.timer_sprite.transform.position = target.Bounds.center + offset
		self.timer_sprite.transform.localRotation = unity_class.quaternion.Euler(45, 0, 0)
		self.timer_sprite.transform:SetParent(target.transform);
		return
	end
end

-- 타이머 UI 해제
function local_class:detach_timer_ui()
	if self.pooled_sprite ~= nil then
		self.pooled_sprite:Dispose()
		self.pooled_sprite = nil
	end
end

-- 카운트 UI 시작하기 위해 붙임
function local_class:attach_count_ui(target, count)
	-- FIXME: 2.10에 X축 0 -> 0.25로 변경
	local offset = vector(0, target.Bounds.size.y + 2, -0.5)
	self.count_ui = unity_object_pool.GetOrCreate('FieldUIDuelBuffState'):Instantiate(target.Position + offset,
		   unity_class.quaternion.identity, target.Transform)

	self.count_ui.transform:Find('Offset').gameObject:SetActive(false)

	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = count
end

-- 카운트 UI 갱신
function local_class:update_count_ui(value)
	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = value
end

-- 카운트 UI 해제
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
