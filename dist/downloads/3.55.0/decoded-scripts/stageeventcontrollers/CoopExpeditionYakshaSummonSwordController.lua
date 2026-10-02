local local_class = newclass('CoopExpeditionYakshaSummonSwordController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	local data = require('stageeventcontrollers/CoopExpeditionYakshaSummonSwordData.lua')[stage.Name]
	self:set_params(data)

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.sword_table = {}

	self.element_table = {'fire', 'water', 'lightning'}

	self.shield_buff_id = 20500

	self.not_destroyed_by_user = false
	self.anim_req_parking =  CS.Oak.AnimationRequest('parking', CS.Oak.AnimationPriorities.Custom, true, 1, -1, nil, nil, nil)
	self.update_table = {}
	self.summon_time_passed = 0
end

function local_class:set_params(data)
	self.fire_sword_name = 'fire_sword'
	self.water_sword_name = 'water_sword'
	self.lightning_sword_name = 'lightning_sword'

	self.summon_sword_message_name = 'summon_sword'
	self.summon_random_sword_message_name = 'summon_random_sword'
	self.park_sword_message_name = 'park_sword'
	self.remove_all_sword_message_name = 'remove_all_sword'
	self.trigger_action_message_name = 'trigger_action'

	self.summon_offset = 2

	self.not_destroyed_park_groggy = data.not_destroyed_park_groggy
	self.destroyed_park_groggy = data.destroyed_park_groggy

	self.summon_sword_shield = data.summon_sword_shield
	self.coop_class_priority = data.coop_class_priority
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_event')
	message_system:Subscribe(self, typeof(CS.Oak.CoopEndEvent), 'on_coop_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.BuffExpiredEvent), 'on_buff_expired_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	self.fire_sword = get_character(self.fire_sword_name)
	self.water_sword = get_character(self.water_sword_name)
	self.lightning_sword = get_character(self.lightning_sword_name)

	unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_sword_fire')
	unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_sword_lightning')
	unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_sword_water')
	unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_sword_fire_floor')
	unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_sword_water_floor')
	unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_sword_lightning_floor')
	unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_sword_fire_end')
	unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_sword_water_end')
	unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_sword_lightning_end')
	unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_shield')
	unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_shiele_break')
	self.fx_prefix = 'fx_co_exp_season1_oni_sword_'
	self.floor_fx_postfix = '_floor'
	self.fx_table = {}
	self.floor_fx_table = {}
end

function local_class:on_buff_expired_event(e)
	if e.Target == self.sender and e.BuffIds:Contains(self.shield_buff_id) and self.current_sword ~= nil then
		self:publish_park_current_sword()
	end
end

function local_class:on_coop_end_event(e)
	if self.sender ~= nil then
		self:publish_remove_all_sword()
	end
end

function local_class:on_field_object_destroyed_event(e)
	if self.sender == nil and e.FieldObject.Name == 'boss_phase_2' or e.FieldObject == self.sender then
		self.sender = get_character('boss_phase_2')
		self:publish_kill_all_sword()
	end
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_damage_event(e)
	if self.current_sword == nil or self.sender == nil or self.kill_sword or not lua_helper.reference_equals(self.current_sword, e.Info.target) then
		return false
	end

	-- 데미지 비헤이비어 변경된 상태면 안보냄
	if CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(self.sender.DamagedBehaviour, typeof(CS.Oak.MonsterDamagedBehaviour)) then
		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.sender = self.current_sword
		damage_info.target = self.sender
		damage_info.damage = e.Info.damage
		damage_info.fireDamage = e.Info.fireDamage
		damage_info.iceDamage = e.Info.iceDamage
		damage_info.earthDamage = e.Info.earthDamage
		damage_info.lightDamage = e.Info.lightDamage
		damage_info.darkDamage = e.Info.darkDamage
		command_util.publish_damage(damage_info)
	end

	return false
end

function local_class:on_custom_event(e)
	if lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		if e:GetParamAt(0) == self.summon_sword_message_name and self.current_sword == nil and #self.element_table > 0 then
			self.sender = e.Sender
			self:publish_summon_sword(self.element_table[1])
			return true

		elseif e:GetParamAt(0) == self.summon_random_sword_message_name and self.current_sword == nil and #self.element_table > 0 then
			self.sender = e.Sender
			self:publish_summon_sword(self.element_table[random_util.get_random_int(1, #self.element_table)])
			return true

		elseif e:GetParamAt(0) == self.park_sword_message_name and self.current_sword ~= nil then
			self.sender = e.Sender
			self.not_destroyed_by_user = true
			buff_manager:RemoveBuff(self.sender, CS.Oak.EquipmentSlot.None, self.sender, 'shield_in_battle')
			return true
		elseif e:GetParamAt(0) == self.remove_all_sword_message_name then
			self.sender = e.Sender
			self:publish_remove_all_sword()
			return true
		elseif e:GetParamAt(0) == self.trigger_action_message_name then
			self.sender = e.Sender
			self:publish_trigger_action()
			return true

		--멀티 연결 끊어진 후 super client 바뀔 때 ai 처리
		elseif e:GetParamAt(0) == 'init_sword_info' then
			message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil,
					{ 'sword_info',
					  self.current_element ~= nil
							  and self.current_element
							  or nil,
					  tostring(#self.element_table),
					  tostring(self.summon_time_passed)}))
		end
	end

	return false
end

function local_class:publish_trigger_action()
	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add(self.trigger_action_message_name)
	info.Strings:Add(self.sender.Name)

	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionYakshaSummonSwordController', info)
	command_util.publish_cmd(self.sender.Owner, command)
end

function local_class:publish_summon_sword(element)
	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add(self.summon_sword_message_name)
	info.Strings:Add(self.sender.Name)
	info.Strings:Add(element)

	info.Positions:Add(self:determine_sword_pos())

	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionYakshaSummonSwordController', info)
	command_util.publish_cmd(self.sender.Owner, command)
end

function local_class:publish_park_current_sword()
	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add(self.park_sword_message_name)
	info.Strings:Add(self.sender.Name)
	info.Positions:Add(self.current_sword.Position)

	if self.not_destroyed_by_user then
		message_system:Publish(CS.Oak.CustomStageEvent.Create(self.character, { 'add_groggy', self.not_destroyed_park_groggy }))
	else
		message_system:Publish(CS.Oak.CustomStageEvent.Create(self.character, { 'add_groggy', self.destroyed_park_groggy }))
	end
	self.not_destroyed_by_user = false
	message_system:Publish(CS.Oak.CustomStageEvent.Create(self.character, { 'try_groggy_trigger' }))

	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionYakshaSummonSwordController', info)
	command_util.publish_cmd(self.sender.Owner, command)
end

function local_class:publish_remove_all_sword()

	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add(self.remove_all_sword_message_name)
	info.Strings:Add(self.sender.Name)

	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionYakshaSummonSwordController', info)
	command_util.publish_cmd(self.sender.Owner, command)
end

function local_class:publish_kill_all_sword()

	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add('kill_all_sword')

	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionYakshaSummonSwordController', info)
	command_util.publish_cmd(self.sender.Owner, command)
end

function local_class:set_boss_invincible()
	buff_manager:AddBuff(self.sender, CS.Oak.EquipmentSlot.None, self.sender, 800014, 9999, false, false)
end

function local_class:remove_boss_invincible()
	buff_manager:RemoveBuff(self.sender, CS.Oak.EquipmentSlot.None, self.sender, 800014)
end

function local_class:sync(info)
	if info.Strings[0] == self.summon_sword_message_name then
		self.sender = get_character(info.Strings[1])
		local target = nil
		if lua_helper.type_compare(self.sender.FieldObjectController.CurrentState, CS.Oak.LuaBattleAIState) then
			target = self.sender.FieldObjectController.CurrentState.MetaTable:get_target()
		end
		local element = info.Strings[2]

		local element_idx = -1
		for i = 1, #self.element_table do
			if self.element_table[i] == element then
				element_idx = i
			end
		end

		if element_idx == -1 then
			return
		else
			table.remove(self.element_table, element_idx)
		end

		--todo: fix
		local ui_dict = stage.FieldUIManager:GetUI(user_party)
		if ui_dict ~= nil and ui_dict:ContainsKey(CS.Oak.FieldUiType.TopHpBarForBoss) then
			local top_hp_bar = ui_dict[CS.Oak.FieldUiType.TopHpBarForBoss]
			if top_hp_bar ~= nil then
				top_hp_bar:TurnOnShieldVisibility()
			end
		end

		local target_sword = self:get_target_sword(element)
		target_sword.CharacterStatsBehaviour:AddStatsOptionRequest(self.cs_controller, CS.Oak.CharacterStatsOptions.All)

		field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.CharacterStats, target_sword)

		local ifo_list = field:GetFieldObjectsInRadius(info.Positions[0], 1)

		for _,fo in pairs(ifo_list) do
			if (fo.EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None then

				local dir = vector_util.normalized(fo.Position - info.Positions[0])
				if vector_util.is_almost_zero(dir) then
					dir = vector_util.normalized(fo.Position - self.sender.Position)
				end

				local damage_info = CS.Oak.DamageInfo()
				damage_info.type = CS.Oak.DamageType.Melee
				damage_info.sender = self.sender
				damage_info.target = fo
				damage_info.modifier = 0
				damage_info.knockBackFactor = CS.Oak.DamageKnockBackConstants.FactorNormalStrong
				damage_info.knockBackDirection = dir
				damage_info.knockBackForce = CS.Oak.DamageKnockBackConstants.StandardForce
				command_util.publish_damage(damage_info)
			end
		end

		table.insert(self.update_table, {
			time_passed = 0,
			sword = target_sword,
			enabled = true,
			update_frame = function(this, dt)
				this.time_passed = this.time_passed + dt
				if this.time_passed > 0.2 then
					this.enabled = false
					this.sword.CrashBehaviour = CS.Oak.MonsterCrashBehaviour.Instance
				end
			end
		})

		target_sword.Position = info.Positions[0]
		target_sword.EntityGroup = CS.Oak.EntityGroups.Enemy0
		target_sword.ActiveState = CS.Oak.ActiveState.Enabled
		target_sword.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
		-- 칼 초기화 된 경우 데미지 들어가므로, 넘버도 보이도록 세팅.
		target_sword.DamagedBehaviour.ShowDamageNumber = true
		self.sender.DamagedBehaviour.ShowDamageNumber = false
		buff_manager:AddShieldBuff(self.sender, CS.Oak.EquipmentSlot.None, self.sender, self.summon_sword_shield)
		self.shield_fx =  unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_shield'):Instantiate(self.sender.Bounds.center, unity_class.quaternion.identity, self.sender.Transform)
		self:set_boss_invincible()

		local notice_level = monster_notice_level['battle']
		local cmd = CS.Oak.MonsterNoticeCommand.Create(target_sword, target,
				notice_level, true, CS.Oak.PlayerReviveOption.None)

		command_util.publish_cmd(self.sender.Owner, cmd)
		self.current_sword = target_sword
		self.current_element = element
		self.fx_table[self.current_element] = unity_object_pool.GetOrCreate(self.fx_prefix .. self.current_element):Instantiate(self.current_sword.Position)
		if self.current_element == 'fire' then
			music_player:PlaySfxOneShot('01_fire_06')
		elseif self.current_element == 'water' then
			music_player:PlaySfxOneShot('02_bluedragon_cast_01')
		elseif self.current_element == 'lightning' then
			music_player:PlaySfxOneShot('01_thunder_01')
		end

		local bf = self.fx_table[self.current_element]:GetComponent(typeof(CS.Spine.Unity.BoneFollower))
		if bf == nil then
			bf = self.fx_table[self.current_element].gameObject:AddComponent(typeof(CS.Spine.Unity.BoneFollower))
		end
		bf.SkeletonRenderer = self.current_sword.SpineController.SkeletonAnimation
		bf:SetBone('sword')

		self.sword_table[element] = target_sword

		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'sword_summoned', element }))
		self.summon_time_passed = 0

	elseif info.Strings[0] == self.park_sword_message_name then
		self.sender = get_character(info.Strings[1])
		local pos = info.Positions[0]

		if self.shield_fx ~= nil then
			self.shield_fx:Dispose()
			self.shield_fx = nil
			unity_object_pool.GetOrCreate('fx_co_exp_season1_oni_shiele_break'):Instantiate(self.sender.Bounds.center, unity_class.quaternion.identity, self.sender.Transform)
		end

		self.sender.DamagedBehaviour.ShowDamageNumber = true
		--set targetsword animation
		self.current_sword.Position = pos
		self.current_sword.ActiveState = CS.Oak.ActiveState.Visible
		self.current_sword.CharacterBehaviour:CancelAllBattleActions(true)
		self.current_sword:SetAnimation(self.cs_controller, self.anim_req_parking)
		-- 주차된 칼은 데미지 넘버 보이지 않도록 세팅
		self.current_sword.DamagedBehaviour.ShowDamageNumber = false
		self.floor_fx_table[self.current_element] = unity_object_pool.GetOrCreate(self.fx_prefix .. self.current_element .. self.floor_fx_postfix):Instantiate(self.current_sword.Position)

		if self.current_element == 'fire' then
			music_player:PlaySfxOneShot('02_fire_slash_03')
		elseif self.current_element == 'water' then
			music_player:PlaySfxOneShot('02_hit_water_01')
		elseif self.current_element == 'lightning' then
			music_player:PlaySfxOneShot('02_hit_light_04')
		end

		if self.fx_table[self.current_element] ~= nil then
			self.fx_table[self.current_element]:Dispose()
			self.fx_table[self. current_element] = nil
		end

		self:remove_boss_invincible()
		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'sword_parked', #self.element_table == 0 and 'all' or '', pos.x .. ', ' .. pos.y .. ', ' .. pos.z, self.current_element}))

		self.current_sword = nil
		self.current_element = nil

	elseif info.Strings[0] == self.remove_all_sword_message_name then
		self.sender = get_character(info.Strings[1])
		self.element_table = {'fire', 'water', 'lightning'}

		for element, sword in  pairs(self.sword_table) do

			local fx = unity_object_pool.GetOrCreate(self.fx_prefix .. element .. '_end'):Instantiate(sword.Position)
			local bf = fx:GetComponent(typeof(CS.Spine.Unity.BoneFollower))
			if bf == nil then
				bf = fx.gameObject:AddComponent(typeof(CS.Spine.Unity.BoneFollower))
			end
			bf.SkeletonRenderer = sword.SpineController.SkeletonAnimation
			bf:SetBone('sword')

			sword.ActiveState = CS.Oak.ActiveState.Disabled
			sword:RemoveAnimation(self.cs_controller)
			sword.CharacterBehaviour:CancelAllBattleActions(true)
		end

		self.sword_table = {}

		self.current_sword = nil
		self.current_element = nil
		for _, fx in pairs(self.fx_table) do
			fx:Dispose()
		end
		self.fx_table = {}

		for _, fx in pairs (self.floor_fx_table) do
			fx:Dispose()
		end
		self.floor_fx_table = {}

	elseif info.Strings[0] == 'kill_all_sword' then
		if self.sender == nil then
			self.sender = get_character('boss_phase_2')
		end

		self.kill_sword = true

		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.sender = self.sender
		damage_info.target = self.fire_sword
		damage_info.damage = self.fire_sword.CharacterStatsBehaviour.MaxHP * 10
		command_util.publish_damage(damage_info)

		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.sender = self.sender
		damage_info.target = self.water_sword
		damage_info.damage = self.water_sword.CharacterStatsBehaviour.MaxHP * 10
		command_util.publish_damage(damage_info)

		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.sender = self.sender
		damage_info.target = self.lightning_sword
		damage_info.damage = self.lightning_sword.CharacterStatsBehaviour.MaxHP * 10
		command_util.publish_damage(damage_info)
	elseif info.Strings[0] == self.trigger_action_message_name then
		self.sender = get_character(info.Strings[1])
		message_system:Publish(CS.Oak.CustomStageEvent.Create(self.sender, { 'trigger_sword_action' }))
	end

end

function local_class:get_target_sword(element)
	if element == 'fire' then
		return self.fire_sword
	elseif element == 'water' then
		return self.water_sword
	elseif element == 'lightning' then
		return self.lightning_sword
	end

	return nil
end

function local_class:determine_sword_pos()
	local class_character_table = {
		[CS.Oak.CoopExpeditionClass.Dealer] = {},
		[CS.Oak.CoopExpeditionClass.Tanker] = {},
		[CS.Oak.CoopExpeditionClass.Healer] = {},
	}
	for i = 0, user_party.Count - 1 do
		if not user_party[i].FieldObjectStatsBehaviour.IsDead then
			table.insert(class_character_table[user_party[i].CharacterStatsBehaviour.CharacterSpec.CoopExpeditionClass], user_party[i])
		end
	end

	for i = 1, #self.coop_class_priority do
		local current_class_table = class_character_table[self.coop_class_priority[i]]
		if #current_class_table ~= 0 then
			return current_class_table[random_util.get_random_int(1, #current_class_table)].Position
		end
	end

	return user_party[random_util.get_random_int(0, user_party.Count - 1)].Position
	--[[
	local bound = CS.UnityEngine.Bounds(vector(0, 0, 0), vector(0.5, 0.75, 0.4))
	local q = unity_class.quaternion.Euler(0, 90, 0)
	local look_vector = direction_util.to_vector3(self.sender.Direction)

	local offset_list = {
		-look_vector,
		q * look_vector,
		q * -look_vector,
		look_vector
	}

	for i = 1, #offset_list do
		local pos = offset_list[i] * self.summon_offset + self.sender.Position
		bound.center = pos + vector(0.5, 0, 0.2)

		local is_collided = false
		local objects = field:GetFieldObjectsCollidedBy(pos, bound, true)
		local fo_list = objects.Values
		for i = 0, fo_list.Count - 1 do
			local fo = fo_list[i]

			if not CS.Oak.ICrashBehaviourExtensions.IsEthereal(fo.CrashBehaviour) and (fo.EntityGroup & CS.Oak.EntityGroups.Obstacle) ~= CS.Oak.EntityGroups.None then
				is_collided = true
				break
			end
		end

		objects:Dispose()

		if field:IsThereFloorAt(pos) and not is_collided then
			return pos
		end
	end

	return vector(0, 0, 0)]]
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return true
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	for i = #self.update_table, 1, -1 do
		if not self.update_table[i].enabled then
			table.remove(self.update_table, i)
		else
			self.update_table[i]:update_frame(dt)
		end
	end

	self.summon_time_passed = self.summon_time_passed + dt
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CoopEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BuffExpiredEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
