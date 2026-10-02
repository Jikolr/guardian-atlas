local local_class = newclass('TowerCountDownWithBreakController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3,
	}
	self.current_progress = self.progress.none

	self.battle_groups = {}

	self.get_custom_sprite = function() return unity_object_pool.GetOrCreate('custom_sprite') end

	self.pooled_sprite = nil
	self.timer_sprite = nil

	-- 게임 타이머 계산용
	self.game_timer = nil
	self.timer = 0
	self.wave = 0
	self.is_break = false

	self.interacting = nil

	self.is_dot_active = false

	self.heal_effect_name = "FX_heal_a"
	self.heal_effect = nil

	-- 박스 오브젝트 생성될 포지션 캐시
	self.heal_object_pos_list = {}

	-- 박스 4개까지 다중 사용 가능하도록 수정
	self.box_names = {"box_1", "box_2", "box_3", "box_4"}
	self.box_objects = {}
	self.box_regen_effects = {}

	self.box_spawn_effect_name = "FX_Obj_Box_spawner"
	self.box_spawn_effect_name2 = "FX_dead"
	self.box_remove_sound_effect_name = "02_explosion_01"

	self.marker_ui_name = 'buff_box'

end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.controller_data = require('stageeventcontrollers/TowerCountDownWithBreakData.lua')
	self.stage_battle_info = self.controller_data[stage.Name]
	self.get_custom_sprite()

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')

	unity_object_pool.GetOrCreate(self.heal_effect_name)
	unity_object_pool.GetOrCreate(self.box_spawn_effect_name)
	unity_object_pool.GetOrCreate(self.box_spawn_effect_name2)

	-- 힐 기믹 위해 상호작용할 박스
	for _, v in pairs(self.box_names) do
		local o = get_field_object(v)
		table.insert(self.box_objects, o)
	end

	for _, v in pairs(self.stage_battle_info.box_marker_names) do
		local pos = {}
		for i, l in pairs(v) do
			local o = field:GetMarker(l)
			table.insert(pos, o.position)
		end
		table.insert(self.heal_object_pos_list, pos)
	end
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
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self:box_remove_all()
	self.box_objects = nil

	if not is_unity_null(self.heal_effect) then
		self.heal_effect:Dispose()
	end
	self.heal_effect = nil

	for _, v in pairs(self.box_regen_effects) do
		if not is_unity_null(v) then
			v:Dispose()
		end
	end

	self.battle_groups = nil
	self.battle_group_names = nil

	self.box_regen_effects = nil

	self.heal_effect_name = nil
	self.box_spawn_effect_name = nil
	self.box_spawn_effect_name2 = nil
	self.box_remove_sound_effect_name = nil

	self.box_names = nil

	self.custom_event_listener = nil
	self.cs_controller = nil
	self.game_timer = nil

	self.timer_sprite = nil
	self:detach_count_ui()
	self:detach_timer_ui()
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'interacting' then
		--버프 부여하고 아이템박스는 안보이게
		self:execute_heal()

		-- 서로 인터렉팅 한 특정 박스 없앰
		for i, v in pairs(self.box_names) do
			if e.Sender.Name == v then
				self:box_remove(i)
			end
		end
	end
end

function local_class:execute_heal()
	-- 힐 정보
	for _,v in pairs(user_party) do
		if not v.CharacterStatsBehaviour.IsDead then
			local heal_info = CS.Oak.HealInfo()
			heal_info.sender = v
			heal_info.target = v
			--최대 hp의 특정 퍼센트 만큼 적용
			heal_info.heal = math.floor(v.CharacterStatsBehaviour.MaxHP * self.stage_battle_info.box_heal_scale)
			music_player:PlaySfxOneShot('02_magic_heal_01')
			self.heal_effect = unity_object_pool.GetOrCreate(self.heal_effect_name):Instantiate(v.Position)
			command_util.execute_heal(heal_info)
		end
	end
end

function local_class:box_remove_all()
	-- 전체 제거시에는 역순으로 하여 Dispose 와 table.remove 하여 테이블에저 전체 제거함.
	local has_any_box_removed = false
	for i = #self.box_regen_effects, 1, -1 do
		if not is_unity_null(self.box_regen_effects[i]) then
			self.box_regen_effects[i]:Dispose()
			table.remove(self.box_regen_effects, i)
			unity_object_pool.GetOrCreate(self.box_spawn_effect_name2):Instantiate(self.box_objects[i].Position)
			has_any_box_removed = true
		end
	end

	for _, v in pairs(self.box_objects) do
		v.Position = vector(999, 0 ,999)
		local marker_name = self.marker_ui_name.._
		ui_quest_marker:RemoveQuestMarker(marker_name)
	end

	if has_any_box_removed then
		music_player_util.play_sfx_one_shot(self.box_remove_sound_effect_name)
	end
end

-- 박스 숨김 ( 오브젝트의 제거는 아님. )
function local_class:box_remove(index)
	--인덱스와 테이블의 포지션을가지고 해당하는 이펙트를 찾아야 하므로 개별 제거시에는 테이블에서 제거하지 않는다.
	if not is_unity_null(self.box_regen_effects[index]) then
		self.box_regen_effects[index]:Dispose()
	end

	self.box_objects[index].Position = vector(999, 0 ,999)

	local marker_name = self.marker_ui_name..index
	ui_quest_marker:RemoveQuestMarker(marker_name)
end

--박스 생성
function local_class:box_create()
	--박스는 생성해둔거 가지고 계속 쓴다.
	local box_index = self.wave
	for _, v in pairs(self.heal_object_pos_list[box_index]) do
		local effect = unity_object_pool.GetOrCreate(self.box_spawn_effect_name):Instantiate(v)
		table.insert(self.box_regen_effects, effect)
		self.box_objects[_].Position = v
		local marker_name = self.marker_ui_name.._
		ui_quest_marker:AddQuestMarkerToPoint(marker_name, -1, false, v + vector(0, 0, 0.4))
	end
end

function local_class:on_stage_loaded_event(_)
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')

	for _, v in pairs(self.stage_battle_info.battle_group_names) do
		local battle_group = stage.BattleManager:GetBattleGroup(v)
		battle_group.SpawnNextWaveAutomatically = false
		table.insert(self.battle_groups, battle_group)
	end

	--self.battle_group = stage.BattleManager:GetBattleGroup(self.stage_battle_info.battle_group_name)
	--self.battle_group.SpawnNextWaveAutomatically = false
	return false
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)

	-- 박스의 interacting 스크립트 가져와서
	for _, v in pairs(self.box_objects) do
		self.interacting = v.FieldObjectBehaviour:GetLuaTable()
		-- 상자와 인터렉트 하는 시간 변경
		self.interacting.interacting_duration = self.stage_battle_info.box_interact_time
	end

	if type_util.is_zone_full_enter(e, user_party.Leader, self.stage_battle_info.battle_group_name) and self.current_progress == self.progress.none then
		self.current_progress = self.progress.playing
		self:start_enemy_count()
	end
	return false
end

function local_class:on_stage_start_event(e)
	-- 클리어 조건 안내
	local show_narration = function()
		field_ui_manager:Hide()
		field_ui_util.show_narration_async({ key = self.stage_battle_info.narration_info })
		field_ui_manager:Show()
	end
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(show_narration))
end

function local_class:on_battle_group_eliminated_event(e)

	if self.wave > self.stage_battle_info.last_wave + 1 then
		return false
	end
		-- 웨이브가 끝나기 전에 적을 처치시 타이머에 남은시간 만큼 보정해준다.
	local cur_total = 0

	for i = 1, self.wave do
		cur_total = cur_total + self.stage_battle_info.wave_intervals[i]

		if i > 1 then
			cur_total = cur_total + self.stage_battle_info.wave_breaks[i - 1]
		end
	end

	if self.timer < cur_total then
		self.add_timer = self.add_timer + (cur_total - self.timer)
		self.timer = self.game_timer.Elapsed + self.add_timer
	end

	return true
end

function local_class:on_field_object_destroyed_event(e)
	-- 보스를 처치하였을 경우에는 프로세스 Cleared
	if lua_helper.type_compare(e.FieldObject.FieldObjectController, CS.Oak.MonsterCharacterController) then
		local boss = get_character(self.stage_battle_info.last_wave_boss_name)
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
function local_class:kill_all_monsters(wave)
	local monsters = self.battle_groups[wave]:GetMonsters()
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

	local cur_total = self.stage_battle_info.wave_intervals[self.wave]

	-- 대충 엄청 길게 하면 됨
	self.game_timer = CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.SingleGameTimer, 36000, nil, CS.Oak.InGameTimer.TimerType.DeltaTime)
	message_system:PublishSync(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, self.game_timer))

	local end_wave_count = self.stage_battle_info.last_wave + 1
	while self.current_progress == self.progress.playing do
		self:update_count_ui(cur_total - math.floor(self.timer + 0.5))

		-- FIXME: 2.10에 다시 사용
		-- self.update_timer_ui(user_party_leader)

		if self.timer >= cur_total then

			if self.is_break == true then
				self.wave = self.wave + 1
				self.is_break = false
				self:box_remove_all()
				message_system:Publish(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(self.stage_battle_info.battle_group_names[self.wave]))
			else
				self:kill_all_monsters(self.wave)
				if self.wave == end_wave_count then
					self.wave = self.wave + 1
				else
					self.is_break = true
					self:box_create()
				end
			end

			-- 마지막 웨이브때는 while문 탈출
			if self.wave > end_wave_count then
				self.current_progress = self.progress.cleared
				break
			else
				if self.is_break == true then
					cur_total = cur_total +  self.stage_battle_info.wave_breaks[self.wave]
				else
					cur_total = cur_total +  self.stage_battle_info.wave_intervals[self.wave]
				end

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

	if self.is_break then
		tmp.color = unity_color({1, 0.82, 0, 1})
	else
		tmp.color = unity_class.color.white
	end
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
