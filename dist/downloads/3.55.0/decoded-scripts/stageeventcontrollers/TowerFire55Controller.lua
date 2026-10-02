local local_class = newclass('TowerFire55Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.battle_monster_fail = nil

	self.wave_monseter_interval = nil

	self.boss_buff_cnt = nil
	self.boss_buff_id = nil
	self.boss_buff_lv = nil

	self.party_atk_buff_id = nil
	self.party_atk_buff_lv = nil
	self.party_shield_buff_ratio = nil

	self.is_battle_start = false

	self.boss = nil
	self.monster_list = { }
	self.idle_monster_list = { } -- pop 가능한 애들

	self.spwan_pos_list = { }

	self.monster_count = 0

	self.time_passed = 0

	-- 미리 배치된 쫄몹 수
	self.max_monster_pool_count = 20

	self.get_custom_sprite = function()
		return unity_object_pool.GetOrCreate('custom_sprite')
	end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over')

	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	local temp_data = require('stageeventcontrollers/TowerFire55Data.lua')
	local data = temp_data[stage.Name]

	self.battle_monster_fail = data.BattleMonterFail

	self.wave_monseter_interval = data.WaveMonsterInterval

	self.boss_buff_cnt = data.BossBuffCnt
	self.boss_buff_id = data.BossBuffId
	self.boss_buff_lv = data.BossBuffLv

	self.party_atk_buff_id = data.PartyAtkBuffId
	self.party_atk_buff_lv = data.PartyAtkBuffLv
	self.party_shield_buff_id = data.PartyShieldBuffId
	self.party_shield_buff_ratio = data.PartyShieldBuffRatio

	self.fx_teleport_pool = unity_object_pool.GetOrCreate('FX_reset_object')

	self:get_custom_sprite()

	return
end

function local_class:late_update_frame(dt)
	if self.is_battle_start == false then
		return
	end

	self.time_passed = self.time_passed + dt

	if self.time_passed >= self.wave_monseter_interval then
		self:spawn_monster()
		self.time_passed = 0
	end
end

function local_class:update_monster_count()
	-- ui update
	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = self.monster_count

	if self.monster_count >= self.battle_monster_fail - 1 then
		tmp.color = unity_class.color.red

	elseif self.monster_count > 4 then
		tmp.color = unity_class.color.yellow

	else
		tmp.color = unity_class.color.white
	end

	-- boss buff update
	self:remove_buff_boss()
	self:add_buff_boss()
end

function local_class:spawn_monster()
	stage.ValueContainer:RemoveValue(CS.Oak.StageValueType.HealDisabled, nil)
	for i = 1, 5 do
		local monster = self:pop_monster()
		if monster ~= nil then
			local pos = self.spwan_pos_list[i]
			self.fx_teleport_pool:Instantiate(pos)
			character_util.set_position(monster, pos)
			self:add_monster_count(1)

			message_system:Publish(CS.Oak.MonsterNoticeEvent.Create(monster, user_party_leader, CS.Oak.MonsterNoticeLevel.Battle))
			message_system:Send(monster.FieldObjectController, CS.Oak.MonsterNoticeEvent.Create(monster, user_party_leader, CS.Oak.MonsterNoticeLevel.Battle))
		end
	end
	stage.ValueContainer:AddValue(CS.Oak.StageValueType.HealDisabled, nil)
end

function local_class:pop_monster()
	if #self.idle_monster_list > 0 then
		local thebattle = stage.BattleManager:GetBattleForMyParty()
		if thebattle == nil then
			return nil
		end

		-- 힐 해주고 보내자
		local monster = table.remove(self.idle_monster_list, 1)
		local heal_info = CS.Oak.HealInfo()
		heal_info.sender = nil
		heal_info.target = monster
		heal_info.isRevive = true
		heal_info.heal = monster.FieldObjectStatsBehaviour.MaxHP
		command_util.execute_heal(heal_info)

		if thebattle ~= nil then
			thebattle:AddEnemy(monster)
			monster.FieldObjectController.DontFight = false
			character_util.set_active_state(monster, 'enabled')
		end

		return monster
	end

	return nil
end

function local_class:push_monster(fo)
	table.insert(self.idle_monster_list, fo)
end

function local_class:kill_monster(fo)
	local damage_info = CS.Oak.DamageInfo()
	damage_info.sender = fo
	damage_info.target = fo
	damage_info.type = CS.Oak.DamageType.Death
	local cmd = CS.Oak.CharacterDeadCommand.Create(damage_info)
	command_util.publish_cmd(fo.Owner, cmd)

	character_util.set_active_state(fo, 'disabled')
	character_util.set_position(fo, vector(999, 0, 999))
	self:push_monster(fo)
	self:add_monster_count(-1)
end

function local_class:add_buff_player()
	local leader = user_party_leader
	for _, v in pairs(user_party) do
		-- add shield
		local amount = math.floor(v.FieldObjectStatsBehaviour.MaxHpWoMod * self.party_shield_buff_ratio)
		buff_manager:AddShieldBuff(leader, CS.Oak.EquipmentSlot.None, v, amount)

		-- add atk buff
		buff_manager:AddBuff(leader, CS.Oak.EquipmentSlot.None, v, self.party_atk_buff_id, self.party_atk_buff_lv, true, false)
	end
end

function local_class:remove_buff_player()
	local leader = user_party_leader
	for _, v in pairs(user_party) do
		buff_manager:RemoveBuff(leader, CS.Oak.EquipmentSlot.None, v, self.party_atk_buff_id)
	end
end

function local_class:add_buff_boss()
	local multiple = self.monster_count / self.boss_buff_cnt
	local buff_lv = math.floor(multiple * self.boss_buff_lv)
	if buff_lv > 0 then
		buff_manager:AddBuff(self.boss, CS.Oak.EquipmentSlot.None, self.boss, self.boss_buff_id, buff_lv, true, false)
	end
end

function local_class:remove_buff_boss()
	buff_manager:RemoveBuff(self.boss, CS.Oak.EquipmentSlot.None, self.boss, self.boss_buff_id)
end

function local_class:add_monster_count(count)
	self.monster_count = self.monster_count + count
	if self.monster_count < 0 then
		self.monster_count = 0
	end

	self:update_monster_count()

	if self.monster_count >= self.battle_monster_fail then
		self:publish_kill_player()
	end
end

function local_class:publish_kill_player()
	local damage_info = CS.Oak.DamageInfo()
	damage_info.sender = user_party.Leader
	damage_info.target = user_party.Leader
	damage_info.direction = direction_util.to_vector3('left')
	damage_info.type = CS.Oak.DamageType.Death
	local cmd = CS.Oak.CharacterDeadCommand.Create(damage_info)
	command_util.publish_cmd(user_party.Leader.Owner, cmd)

	-- 게임 오버 이벤트 중첩 방지
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))

	self:on_game_over(nil)
end

function local_class:attach_count_ui(target)
	local offset = vector(0.25, target.Bounds.size.y + 2, -0.5)
	self.count_ui = unity_object_pool.GetOrCreate('FieldUIDuelBuffState'):Instantiate(target.Position + offset,
			unity_class.quaternion.identity, target.Transform)

	self.count_ui.transform:Find('Offset').gameObject:SetActive(false)

	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = 0
end

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

function local_class:clear_stage()
	for _, v in pairs(self.monster_list) do
		self:kill_monster(v)
	end

	stage.BattleManager:ForceEndBattles()
end

function local_class:on_stage_loaded(e)
	self.boss = get_character('raid_boss')

	for i = 1, self.max_monster_pool_count do
		local fo = get_character('monster_' .. i)
		if fo ~= nil then
			fo.EntityGroup = CS.Oak.EntityGroups.Enemy6
			character_util.set_active_state(fo, 'disabled')
			table.insert(self.monster_list, fo)
			self:push_monster(fo)
		end
	end

	for i = 1, 5 do
		local marker = field:GetMarker('spawn_' .. i)
		table.insert(self.spwan_pos_list, marker.position)
	end

	stage.ValueContainer:Dispose()
	local value_container = CS.Oak.StageValueContainer()
	stage.ValueContainer = value_container

	stage.ValueContainer:AddValue(CS.Oak.StageValueType.HealDisabled, nil)
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')
end

function local_class:on_battle_start(e)
	if self.is_battle_start == false then
		self.is_battle_start = true
		self:attach_count_ui(user_party_leader)
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attach_image_ui, self, user_party_leader))

		self.time_passed = self.wave_monseter_interval
	end
end

function local_class:on_field_object_destroyed(e)
	-- boss check
	if lua_helper.reference_equals(self.boss, e.FieldObject) then
		self.is_battle_start = false
		self:clear_stage()

	elseif e.FieldObject.EntityGroup == CS.Oak.EntityGroups.Enemy6 then
		self:add_buff_player()

		character_util.set_position(e.FieldObject, vector(999, 0, 999))
		character_util.set_active_state(e.FieldObject, 'disabled')
		self:push_monster(e.FieldObject)
		self:add_monster_count(-1)
	end
end

function local_class:on_game_over(e)
	self.is_battle_start = false
	self:clear_stage()
end

function local_class:use_late_update_frame()
	return true
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
