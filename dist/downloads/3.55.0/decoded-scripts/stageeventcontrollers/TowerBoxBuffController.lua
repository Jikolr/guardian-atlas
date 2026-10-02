local local_class = newclass('TowerBoxBuffController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	self.box_spawn_marker_name = "item_spawn_position_"
	self.box_name = "item_box_0"
	self.box_regen_time = 3
	self.buff_duration = 7
	self.buff_id = 10001
	self.buff_level = 500

	self.box_object = nil
	self.box_spawn_markers = {}
	self.buff_effect_list = {}

	--effect
	self.effect_name = "elemental_tower_buff"
	self.box_spawn_effect_name = "FX_Obj_Box_spawner"
	self.box_spawn_effect_name2 = "FX_dead"
	self.box_regen_effect_duration = 1.5
	self.is_box_regen_effect = false
	self.box_regen_effect_time_passed = 0
	self.box_regen_effect = nil
	self.count_ui = nil

	-- 시간 경과 변수
	self.time_passed = 0

	self.is_add_buff = false
	self.is_box_regen = true

	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.box_object = get_field_object(self.box_name)

	for i = 1, 4 do
		local marker = field:GetMarker(self.box_spawn_marker_name .. i - 1)
		table.insert(self.box_spawn_markers, marker)
	end

	unity_object_pool.GetOrCreate(self.effect_name)
	unity_object_pool.GetOrCreate(self.box_spawn_effect_name)
	unity_object_pool.GetOrCreate(self.box_spawn_effect_name2)
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'interacting' then
		if not self.is_box_regen then

			--버프 부여하고 아이템박스는 안보이게
			self:add_buff()
			self.box_object.Position = vector(999, 0 ,999)
			self.is_box_regen = true
			self.is_add_buff = true

			quest_marker_util.remove('buff_box')
		end
	end
end

function local_class:on_launch(_)
end

function local_class:on_battle_start_event(e)
	self.current_progress = self.progress.playing
	self.is_add_buff = false
	self.is_box_regen = true
end

function local_class:on_battle_end_event(e)
	self.current_progress = self.progress.none
	self:detach_count_ui()
	self.box_object.Position = vector(999, 0 ,999)
	quest_marker_util.remove('buff_box')

	if self.box_regen_effect ~= nil then
		self.box_regen_effect:Dispose()
	end

	for _,v in pairs(self.buff_effect_list) do
		if v ~= nil then
			v:Dispose()
		end
	end
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return true end

	if self.is_box_regen then
		if self.is_add_buff then
			for i = 0, user_party.Count - 1 do
				if user_party[i].FieldObjectStatsBehaviour.IsDead then
					if self.buff_effect_list[i] ~= nil then
						self.buff_effect_list[i]:Dispose()
						self.buff_effect_list[i] = nil
					end
				end
			end

			if self.time_passed >= self.buff_duration then
				self.time_passed = 0
				self.is_add_buff = false
				self.count_ui.gameObject:SetActive(false)

				for i = 0, user_party.Count - 1 do
					if self.buff_effect_list[i] ~= nil then
						self.buff_effect_list[i]:Dispose()
						self.buff_effect_list[i] = nil
					end
				end
			else
				self.time_passed = self.time_passed + dt
				self:update_count_ui(self.buff_duration - math.floor(self.time_passed + 0.5))
			end
		else
			if self.time_passed >= self.box_regen_time then
				self:box_regen()
				self.is_box_regen = false
				self.time_passed = 0
			else
				self.time_passed = self.time_passed + dt
			end
		end
	end

	if self.is_box_regen_effect then
		if self.box_regen_effect_time_passed >= self.box_regen_effect_duration then
			self.is_box_regen_effect = false
			self.box_regen_effect_time_passed = 0
			self.box_regen_effect:Dispose()
			self.box_regen_effect = nil
		else
			self.box_regen_effect_time_passed = self.box_regen_effect_time_passed + dt
		end
	end
end

function local_class:box_regen()
	local rand = math.floor(CS.UnityEngine.Random.Range(1, 4))
	self.box_regen_effect = unity_object_pool.GetOrCreate(self.box_spawn_effect_name):Instantiate(self.box_spawn_markers[rand].position)
	unity_object_pool.GetOrCreate(self.box_spawn_effect_name2):Instantiate(self.box_spawn_markers[rand].position)
	self.is_box_regen_effect = true
	self.box_object.Position = self.box_spawn_markers[rand].position
	ui_quest_marker:AddQuestMarkerToPoint("buff_box", -1,
			false, self.box_spawn_markers[rand].position + vector(0, 0, 0.4))
end

function local_class:add_buff()
	for i = 0, user_party.Count - 1 do
		if not user_party[i].FieldObjectStatsBehaviour.IsDead then
			local effect_pos = user_party[i].Position + user_party[i].SpineController.SpineTotalOffset + -0.1 * unity_class.vector3.up
			local effect = unity_object_pool.GetOrCreate(self.effect_name):Instantiate(effect_pos)
			effect.transform.localRotation = unity_class.quaternion.Euler(0, -90, 0)
			effect.transform.parent = user_party[i].SpineController.SpineContainerTransform
			effect.transform.localScale = vector(1, 1.5, 1.2)
			self.buff_effect_list[i] = effect
			stage.BuffManager:AddBuff(user_party[i], CS.Oak.EquipmentSlot.None, user_party[i], self.buff_id, self.buff_level, false, false)
			if is_unity_null(self.count_ui) then
				self:attach_count_ui(user_party[i], self.buff_duration)
			else
				self.count_ui.gameObject:SetActive(true)
				self:update_count_ui(self.buff_duration)
			end
		end
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

function local_class:detach_count_ui()
	if self.count_ui ~= nil then
		self.count_ui.transform:Find('Offset').gameObject:SetActive(true)
		self.count_ui:Dispose()
		self.count_ui = nil
	end
end

-- 카운트 UI 갱신
function local_class:update_count_ui(value)
	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = value
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil

	self.box_object = nil
	self.box_spawn_markers = nil

	if self.box_regen_effect ~= nil then
		self.box_regen_effect:Dispose()
	end

	for _,v in pairs(self.buff_effect_list) do
		if v ~= nil then
			v:Dispose()
		end
	end

	self.buff_effect_list = nil
	self.box_regen_effect = nil
	self.count_ui = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
