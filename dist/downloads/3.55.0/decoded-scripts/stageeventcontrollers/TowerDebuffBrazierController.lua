local local_class = newclass("TowerDebuffBrazierController")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	-- initialize data
	self.start = false

	self.get_fx_darkness_target = function()
		return unity_object_pool.GetOrCreate('fx_dragon_warehouse_stencil_mask')
	end
	self.get_fx_darkness_background = function()
		return unity_object_pool.GetOrCreate('fx_dragon_warehouse_background')
	end

	-- parse data
	local stage_battle_info = require('stageeventcontrollers/TowerDebuffBrazierData.lua')
	local data_set = stage_battle_info[stage.Name]

	self.event_key = data_set.event_key
	self.background_color = unity_color(data_set.background_color)
	self.brazier_distance = data_set.brazier_distance
	self.brazier_effect_offset = vector(data_set.brazier_effect_offset[1], data_set.brazier_effect_offset[2], data_set.brazier_effect_offset[3])
	self.brazier_effect_scale = vector(data_set.brazier_effect_scale[1], data_set.brazier_effect_scale[2], data_set.brazier_effect_scale[3])
	self.debuff_data = data_set.debuff_data
	self.monster_buff_data = data_set.monster_buff_data

	self.brazier_list = {}
	for _, b_name in ipairs(data_set.brazier_names) do
		local fo = get_field_object(b_name)
		if not is_unity_null(fo) then
			local data = {
				field_object = fo
			}
			table.insert(self.brazier_list, data)
		end
	end
end

function local_class:load_resource()
	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource(controller)
	-- 필요한 리소스 로드 및 이벤트 subs
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	quest_util.load_pool_resource(
			'fx_dragon_warehouse_stencil_mask',
			'fx_dragon_warehouse_background'
	)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_event(e)
	--local event_type = e:GetType()
	return false
end

function local_class:on_stage_loaded(e)
	for _, brazier_data in ipairs(self.brazier_list) do
		local brazier = brazier_data.field_object
		local burning = brazier.CombustibleBehaviour.IsBurning

		local effect = self.get_fx_darkness_target():Instantiate(brazier.Position  + self.brazier_effect_offset)
		effect.transform.localScale = self.brazier_effect_scale
		effect.gameObject:SetActive(burning)

		local compos = effect:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))

		if compos.Length == 2 then
			compos[1].material.color = self.background_color
		end

		brazier_data.effect = effect
	end

	self.dark_effect = self.get_fx_darkness_background():Instantiate(stage_camera.transform.position,
			unity_class.quaternion.Euler(-45, 0, 0), stage_camera.transform)
	self.dark_effect.transform.localScale = vector(3, 1, 2)

	local compo = self.dark_effect:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))

	if compo.Length == 1 then
		compo[0].material.color = self.background_color
	end

end

function local_class:on_stage_start(e)
	self.start = true
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == self.event_key then
		local sender = e.Sender
		for _, brazier_data in ipairs(self.brazier_list) do
			local brazier = brazier_data.field_object
			local burning = brazier.CombustibleBehaviour.IsBurning

			if burning == true then
				local cmd = CS.Oak.ExtinguishCommand.Create(sender, brazier)
				command_util.publish_cmd(sender.Owner, cmd)
			else
				local cmd = CS.Oak.BurnCommand.Create(sender, brazier)
				command_util.publish_cmd(sender.Owner, cmd)
			end
		end
	end
end

function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	if self.start then
		-- 화로 이펙트 갱신
		for _, brazier_data in ipairs(self.brazier_list) do
			local brazier = brazier_data.field_object
			local burning = brazier.CombustibleBehaviour.IsBurning

			if burning == true then
				-- 이펙트 켜기
				if not brazier_data.effect.isActiveAndEnabled then
					brazier_data.effect.gameObject:SetActive(true)
				end

			else
				-- 이펙트 끄기
				if brazier_data.effect.isActiveAndEnabled then
					brazier_data.effect.gameObject:SetActive(false)
				end
			end
		end

		-- 디버프 처리
		for i = 0, user_party.Count - 1 do
			local target_character = user_party[i]
			local close_to_brazier = false

			-- 화로 근처에 있는지 체크
			for _, brazier_data in ipairs(self.brazier_list) do
				local brazier = brazier_data.field_object

				if brazier.CombustibleBehaviour.IsBurning == true then
					if vector_util.get_x0z(brazier.Position - target_character.Position).magnitude <= self.brazier_distance then
						close_to_brazier = true
						break
					end
				end
			end

			if close_to_brazier then
				-- 불 켜진 화로 근처에 있으면 디버프 제거
				for _, debuff_info in ipairs(self.debuff_data) do
					local debuff_id = debuff_info[1]
					if target_character.FieldObjectStatsBehaviour:IsActiveBuff(debuff_id) then
						stage.BuffManager:RemoveBuff(target_character, CS.Oak.EquipmentSlot.None, target_character, debuff_id)
					end
				end
			else
				-- 불 켜진 화로 근처에 있지 않으면 디버프 적용
				for _, debuff_info in ipairs(self.debuff_data) do
					local debuff_id = debuff_info[1]
					local debuff_level = debuff_info[2]
					if not target_character.FieldObjectStatsBehaviour:IsActiveBuff(debuff_id) then
						stage.BuffManager:AddBuff(target_character, CS.Oak.EquipmentSlot.None, target_character, debuff_id, debuff_level, false, false)
					end
				end
			end
		end

		-- 몬스터 버프 기능 추가
		local current_battle = stage.BattleManager:GetBattleForMyParty()
		if current_battle ~= nil then
			local enemies = current_battle.Enemies
			for i = 0, enemies.Count -1 do
				local target_character = enemies[i].Character
				if stage.BattleManager:IsCharacterInActiveBattle(target_character) then
					local close_to_brazier = false

					-- 화로 근처에 있는지 체크
					for _, brazier_data in ipairs(self.brazier_list) do
						local brazier = brazier_data.field_object

						if brazier.CombustibleBehaviour.IsBurning == true then
							if vector_util.get_x0z(brazier.Position - target_character.Position).magnitude <= self.brazier_distance then
								close_to_brazier = true
								break
							end
						end
					end

					if close_to_brazier then
						-- 불 켜진 화로 근처에 있으면 버프 제거
						for _, buff_info in ipairs(self.monster_buff_data) do
							local buff_id = buff_info[1]
							if target_character.FieldObjectStatsBehaviour:IsActiveBuff(buff_id) then
								stage.BuffManager:RemoveBuff(target_character, CS.Oak.EquipmentSlot.None, target_character, buff_id)
							end
						end
					else
						-- 불 켜진 화로 근처에 있지 않으면 버프 적용
						for _, buff_info in ipairs(self.monster_buff_data) do
							local buff_id = buff_info[1]
							local buff_level = buff_info[2]
							if not target_character.FieldObjectStatsBehaviour:IsActiveBuff(buff_id) then
								stage.BuffManager:AddBuff(target_character, CS.Oak.EquipmentSlot.None, target_character, buff_id, buff_level, false, false)
							end
						end
					end
				end
			end
		end
	end
end

function local_class:dispose()
	self.start = false

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	if self.brazier_list ~= nil then
		for _, brazier_data in pairs(self.brazier_list) do
			if not is_unity_null(brazier_data.effect) then
				brazier_data.effect:Dispose()
			end
		end
	end
	self.brazier_list = nil

	if not is_unity_null(self.dark_effect) then
		self.dark_effect:Dispose()
	end
	self.dark_effect = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
