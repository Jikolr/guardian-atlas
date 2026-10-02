local local_class = newclass('TowerLight50BoxBuffController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	self.stage_battle_info = {
		tower_light_50 = {
			--버프를 받을 몬스터 이름
			boss_names = {
				'boss_robot_knight'
			},
			--적용할 버프 리스트
			buff_ids = {
				10000,
				20000,
			},
			--적용할 버프 레벨
			buff_levels = {
				20,
				20
			},
			--적용할 힐 수치
			heal_modifier = 0.05,
			--오브젝트가 사라진 뒤 리젠 되기까지 걸리는 시간
			regen_duration = 4.5,
			--오브젝트가 생성된 후 사라지기까지 걸리는 시간
			time_limit = 6.5,
			--오브젝트 생설될 마커위치 갯수
			marker_count = 4,
			--수치표시 UI offset
			ui_offset = vector(0, -1, -0.5),

			--Blockaura effect offset
			buff_effect_scale = vector(1.75, 1.5, 1.75),
			buff_effect_offset = vector(0, -0.75, 0),

			--버프 최대 중첩 카운트
			max_buff_count = 500
		}
	}

	self.spawn_marker_name = "spawn_position_"
	self.buff_robot_name = "robot"

	self.buff_robot = nil
	self.target_monsters = nil
	self.robot_spawn_markers = {}
	self.buff_holder = nil

	--effect
	self.spawn_effect_name = "FX_Obj_Box_spawner"
	self.spawn_effect_name2 = "FX_dead"
	self.buff_effect_name = "FX_Blockaura_Char_Boss"
	self.robot_hide_effect_name = "FX_reset_object"
	self.robot_regen_effect_duration = 1.5
	self.is_robot_regen_effect = false
	self.robot_regen_effect_time_passed = 0
	self.robot_regen_effect = nil

	self.count_ui_list = nil

	--오브잭트 놓친 카운트
	self.missed_robot_count = 0

	-- 시간 경과 변수
	self.time_passed = 0
	self.is_buff_robot_regen = false
	self.current_stage_info = nil
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.buff_robot = get_character(self.buff_robot_name)
	-- 버프 추가 및 해지 등을 명시적으로 하기 위해 있을 홀더
	self.buff_holder = stage:GetCharacter('buff_holder')

	self.current_stage_info = self.stage_battle_info[stage.Name]
	for i = 1, self.current_stage_info.marker_count do
		local marker = field:GetMarker(self.spawn_marker_name .. i - 1)
		table.insert(self.robot_spawn_markers, marker)
	end

	self.target_monsters = {}
	for i = 1, #self.current_stage_info.boss_names do
		local monster = stage:GetCharacter(self.current_stage_info.boss_names[i])
		table.insert(self.target_monsters, monster)
	end

	unity_object_pool.GetOrCreate(self.spawn_effect_name)
	unity_object_pool.GetOrCreate(self.spawn_effect_name2)
	unity_object_pool.GetOrCreate(self.buff_effect_name)
	unity_object_pool.GetOrCreate(self.robot_hide_effect_name)
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')

	self.regen_duration = self.current_stage_info.regen_duration
	self.object_time_limit = self.current_stage_info.time_limit
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_field_object_destroyed_event(e)
	if self.current_progress ~= self.progress.playing then return end

	if lua_helper.reference_equals(e.FieldObject, self.buff_robot) then
		quest_marker_util.remove('buff_object')
		self.is_buff_robot_regen = false
		self.time_passed = 0
	end

	if table_util.contain_value(self.boss_list, e.FieldObject) then

	end
end

function local_class:on_battle_start_event(e)
	if self.current_progress == self.progress.playing then return end

	self.current_progress = self.progress.playing
	self.is_buff_robot_regen = false

	if self.count_ui_list == nil then
		self.count_ui_list = {}
	end
end

function local_class:on_battle_end_event(e)
	if self.current_progress ~= self.progress.playing then return end

	self.current_progress = self.progress.none

	for _,v in pairs(self.count_ui_list) do
		self:detach_count_ui(v)
	end

	self:kill_buff_robot()
	quest_marker_util.remove('buff_object')

	if self.robot_regen_effect ~= nil then
		self.robot_regen_effect:Dispose()
	end
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return true end

	if not self.is_buff_robot_regen then
		if self.time_passed >= self.regen_duration then
			self:buff_robot_regen()
			self.is_buff_robot_regen = true
			self.time_passed = 0
			return
		else
			self.time_passed = self.time_passed + dt
		end
	elseif self.is_buff_robot_regen then
		if self.time_passed >= self.object_time_limit then
			--로봇 삭제, 삭제카운트증가, 버프갱신
			quest_marker_util.remove('buff_object')

			if self.missed_robot_count < self.current_stage_info.max_buff_count then
				self.missed_robot_count = self.missed_robot_count + 20
				self:update_buff()
			end

			--robot hide
			self:missed_buff_robot()
			self.is_buff_robot_regen = false
			self.time_passed = 0
			return
		else
			self.time_passed = self.time_passed + dt
		end
	end

	if self.is_robot_regen_effect then
		if self.robot_regen_effect_time_passed >= self.robot_regen_effect_duration then
			self.is_robot_regen_effect = false
			self.robot_regen_effect_time_passed = 0
			self.robot_regen_effect:Dispose()
			self.robot_regen_effect = nil
		else
			self.robot_regen_effect_time_passed = self.robot_regen_effect_time_passed + dt
		end
	end
end

function local_class:kill_buff_robot()
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap | CS.Oak.DamageType.Death
	damage_info.notMortal = false
	damage_info.sender = self.buff_robot
	damage_info.target = self.buff_robot
	damage_info.damage = self.buff_robot.FieldObjectStatsBehaviour.MaxHP * 2

	command_util.execute_damage(damage_info)
end

function local_class:missed_buff_robot()
	unity_object_pool.GetOrCreate(self.robot_hide_effect_name):Instantiate(self.buff_robot.Position)
	self.buff_robot.Position = vector(999, 0, 999)
end

--랜덤 마커위치에 버프로봇 생성
function local_class:buff_robot_regen()
	local rand = math.floor(CS.UnityEngine.Random.Range(1, self.current_stage_info.marker_count))

	--리젠 이펙트
	self.robot_regen_effect = unity_object_pool.GetOrCreate(self.spawn_effect_name):Instantiate(
			self.robot_spawn_markers[rand].position)
	unity_object_pool.GetOrCreate(self.spawn_effect_name2):Instantiate( self.robot_spawn_markers[rand].position)

	self.is_robot_regen_effect = true
	self.buff_robot.Position = self.robot_spawn_markers[rand].position

	--힐
	local heal_info = CS.Oak.HealInfo()
	heal_info.type = CS.Oak.HealType.Normal
	heal_info.heal = self.buff_robot.CharacterStatsBehaviour.MaxHP
	heal_info.isRevive = true
	heal_info.sender = self.buff_holder
	heal_info.target = self.buff_robot
	heal_info.skipEffect = true

	local cmd = CS.Oak.HealCommand.Create(heal_info)
	command_util.publish_cmd(heal_info.Owner, cmd)

	ui_quest_marker:AddQuestMarkerToPoint("buff_object", -1,
			false, self.robot_spawn_markers[rand].position + vector(0, 0, 0.6))
end

--타겟에게 버프 적용, 기존적용된 버프 삭제 후 새로운 Level로 새로 부여
function local_class:update_buff()
	for i = 1, #self.target_monsters do
		if self.count_ui_list[i] == nil then
			self.count_ui_list[i] = self:attach_count_ui(self.target_monsters[i], self.missed_robot_count)
			self:attach_buff_effect(self.target_monsters[i])
		else
			self:update_count_ui(self.count_ui_list[i], self.missed_robot_count)
		end

		for j = 1,  #self.current_stage_info.buff_ids do
			buff_manager:RemoveBuff(self.buff_holder, CS.Oak.EquipmentSlot.None, self.target_monsters[i],
			self.current_stage_info.buff_ids[j])

			buff_manager:AddBuff(self.buff_holder, CS.Oak.EquipmentSlot.None, self.target_monsters[i],
					self.current_stage_info.buff_ids[j],
					self.current_stage_info.buff_levels[j] * self.missed_robot_count, false, false)
		end

		--힐
		local heal_info = CS.Oak.HealInfo()
		heal_info.type = CS.Oak.HealType.Normal
		heal_info.heal = math.floor(self.target_monsters[i].CharacterStatsBehaviour.MaxHP * self.current_stage_info.heal_modifier)
		heal_info.sender = self.buff_holder
		heal_info.target = self.target_monsters[i]

		local cmd = CS.Oak.HealCommand.Create(heal_info)
		command_util.publish_cmd(heal_info.Owner, cmd)
	end
end

function local_class:attach_buff_effect(target)
	local effect_pos = target.Position + target.SpineController.SpineTotalOffset + -0.1 * unity_class.vector3.up +
			self.current_stage_info.buff_effect_offset
	local effect = unity_object_pool.GetOrCreate(self.buff_effect_name):Instantiate(effect_pos)
	effect.transform.localRotation = unity_class.quaternion.Euler(0, 0, 0)
	effect.transform.parent = target.SpineController.SpineContainerTransform
	effect.transform.localScale = self.current_stage_info.buff_effect_scale
	return effect
end

-- 카운트 UI 시작하기 위해 붙임
function local_class:attach_count_ui(target, count)
	-- FIXME: 2.10에 X축 0 -> 0.25로 변경
	local offset = self.current_stage_info.ui_offset + vector(0, target.Bounds.size.y, 0)
	local count_ui = unity_object_pool.GetOrCreate('FieldUIDuelBuffState'):Instantiate(target.Position + offset,
			unity_class.quaternion.identity, target.Transform)

	count_ui.transform:Find('Offset').gameObject:SetActive(false)

	local tmp = count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = string.format('%d%%', count)

	return count_ui
end

function local_class:detach_count_ui(ui_object)
	if ui_object ~= nil then
		ui_object.transform:Find('Offset').gameObject:SetActive(true)
		ui_object:Dispose()
		ui_object = nil
	end
end

-- 카운트 UI 갱신
function local_class:update_count_ui(ui_object, value)
	local tmp = ui_object.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = string.format("%d%%", value)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil

	self.stage_battle_info = nil
	self.buff_robot = nil
	self.target_monsters = nil
	self.robot_spawn_markers = nil
	self.count_ui_list = nil
	self.buff_holder = nil
	self.current_stage_info = nil

	if self.robot_regen_effect ~= nil then
		self.robot_regen_effect:Dispose()
	end

	self.robot_regen_effect = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
