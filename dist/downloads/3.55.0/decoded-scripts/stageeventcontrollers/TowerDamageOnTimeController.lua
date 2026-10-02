local local_class = newclass('TowerDamageOnTimeController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	-- 스테이지별 정보를 담고 있는 구조체
	self.stage_battle_info = require('stageeventcontrollers/TowerDamageOnTimeData.lua')

	self.interacting = nil

	self.is_dot_active = false

	self.heal_effect_name = "FX_heal_a"
	self.heal_effect = nil

	-- 박스 오브젝트 생성될 포지션 캐시
	self.heal_object_pos_list = {}

	self.boss = nil
	self.current_hp_phase = 1

	-- 박스 다섯개까지 다중 사용 가능하도록 수정
	self.box_names = {"item_box_0", "item_box_1", "item_box_2", "item_box_3", "item_box_4"}
	self.box_objects = {}
	self.box_regen_effects = {}

	self.box_spawn_effect_name = "FX_Obj_Box_spawner"
	self.box_spawn_effect_name2 = "FX_dead"

	self.marker_ui_name = 'buff_box'

	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]

	-- 나중에 없을수 있어서 미리 로드 해둠.
	unity_object_pool.GetOrCreate(self.box_spawn_effect_name)
	unity_object_pool.GetOrCreate(self.box_spawn_effect_name2)
	unity_object_pool.GetOrCreate(self.heal_effect_name)

	-- hp 파악하기위한 보스
	self.boss = get_character(self.current_stage_info.boss_name)

	-- 힐 기믹 위해 상호작용할 박스
	for _, v in pairs(self.box_names) do
		local o = get_field_object(v)
		table.insert(self.box_objects, o)
	end

	for _, v in pairs(self.current_stage_info.box_marker_names) do
		local pos = {}
		for i, l in pairs(v) do
			local o = field:GetMarker(l)
			table.insert(pos, o.position)
		end
		table.insert(self.heal_object_pos_list, pos)
	end
	return
end

-- 도트 데미지 루틴 시작
function local_class:start_dot()
	local time_passed = 0
	self.is_dot_active = true

	while self.is_dot_active do
		if time_passed > self.current_stage_info.damage_term then
			-- 대미지 정보
			for _,v in pairs(user_party) do
				if not v.CharacterStatsBehaviour.IsDead then
					local damage_info = CS.Oak.DamageInfo()
					damage_info.type = CS.Oak.DamageType.DotDamage | CS.Oak.DamageType.Death | CS.Oak.DamageType.Passive
					damage_info.sender = v
					damage_info.target = v
					damage_info.direction = unity_class.vector3.zero
					damage_info.noCritical = true
					damage_info.damage = unity_class.mathf.Floor(v.FieldObjectStatsBehaviour.MaxHP
							* self.current_stage_info.damage_scale)
					command_util.execute_damage(damage_info)
				end
			end

			time_passed = 0
		else
			time_passed = time_passed + unity_class.time.deltaTime
		end

		coroutine.yield(nil)
	end
end

--도트 데미지 들어가는것 종료함.
function local_class:end_dot()
	self.is_dot_active = false;
end

function local_class:excute_heal()
	-- 힐 정보
	for _,v in pairs(user_party) do
		if not v.CharacterStatsBehaviour.IsDead then
			local heal_info = CS.Oak.HealInfo()
			heal_info.sender = v
			heal_info.target = v
			--최대 hp의 특정 퍼센트 만큼 적용
			heal_info.heal = math.floor(v.CharacterStatsBehaviour.MaxHP * self.current_stage_info.box_heal_scale)
			music_player:PlaySfxOneShot('02_magic_heal_01')
			self.heal_effect = unity_object_pool.GetOrCreate(self.heal_effect_name):Instantiate(v.Position)
			command_util.execute_heal(heal_info)
		end
	end
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.current_stage_info.zone_name) then
		if self.current_progress ~= self.progress.none then
			return
		end
		-- 박스의 interacting 스크립트 가져와서
		for _, v in pairs(self.box_objects) do
			self.interacting = v.FieldObjectBehaviour:GetLuaTable()
			-- 상자와 인터렉트 하는 시간 변경
			self.interacting.interacting_duration = self.current_stage_info.box_interact_time
		end
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_dot, self))
		self.current_progress = self.progress.playing
	end
end

-- 배틀존 종료되면 클리어
function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.current_stage_info.end_battle_group_name then
		--도트 데미지 종료
		self:end_dot()
		-- 박스 제거
		self:box_remove_all()
		-- 전명했으면 클리어
		self.current_progress = self.progress.cleared
	end
end

--상자 인터렉션 끝나면 힐
function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'interacting' then
		--버프 부여하고 아이템박스는 안보이게
		self:excute_heal()

		-- 서로 인터렉팅 한 특정 박스 없앰
		for i, v in pairs(self.box_names) do
			if e.Sender.Name == v then
				self:box_remove(i)
			end
		end
	end
end

-- 데미지 받았을때 보스 hp 가 각 단계의 boss_hp_percent 이하이면 박스 생성
function local_class:on_damage_event(e)
	if lua_helper.reference_equals(e.Info.target, self.boss) then
		if self.current_hp_phase <= #self.current_stage_info.boss_hp_percent then
			if self.boss.CharacterStatsBehaviour.HpRatio < self.current_stage_info.boss_hp_percent[self.current_hp_phase] then
				--hp 다음단계로
				self.current_hp_phase = self.current_hp_phase + 1;
				-- 기존박스 남아있다편 제거
				self:box_remove_all()
				-- 새 박스 생성
				self:box_create()
			end
		end
	elseif lua_helper.reference_equals(e.Info.target, user_party_leader) then
		if user_party_leader.CharacterStatsBehaviour.HpRatio <= 0 then
			-- 리더가 죽어 게임 종료되는 경우에 코루틴 정지 시키기 위함
			self.is_dot_active = false
		end
	end
end

-- 전체 박스 숨김 ( 오브젝트의 제거는 아님. )
function local_class:box_remove_all()
	-- 전체 제거시에는 역순으로 하여 Dispose 와 table.remove 하여테이블에저 전체 제거함.
	for i = #self.box_regen_effects, 1, -1 do
		if not is_unity_null(self.box_regen_effects[i]) then
			self.box_regen_effects[i]:Dispose()
			table.remove(self.box_regen_effects, i)
		end
	end

	for _, v in pairs(self.box_objects) do
		v.Position = vector(999, 0 ,999)
		local marker_name = self.marker_ui_name.._
		ui_quest_marker:RemoveQuestMarker(marker_name)
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
	local box_index = self.current_hp_phase - 1
	for _, v in pairs(self.heal_object_pos_list[box_index]) do
		local effect = unity_object_pool.GetOrCreate(self.box_spawn_effect_name):Instantiate(v)
		table.insert(self.box_regen_effects, effect)
		unity_object_pool.GetOrCreate(self.box_spawn_effect_name2):Instantiate(v)
		self.box_objects[_].Position = v
		local marker_name = self.marker_ui_name.._
		ui_quest_marker:AddQuestMarkerToPoint(marker_name, -1, false, v + vector(0, 0, 0.4))
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))

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
	self.box_regen_effects = nil

	self.current_stage_info = nil
	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
	self.stage_battle_info = nil
	self.interacting = nil
	self.is_dot_active = nil
	self.heal_effect_name = nil
	self.heal_object_pos_list = nil
	self.boss = nil
	self.current_hp_phase = nil
	self.box_names = nil
	self.box_spawn_effect_name = nil
	self.box_spawn_effect_name2 = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
