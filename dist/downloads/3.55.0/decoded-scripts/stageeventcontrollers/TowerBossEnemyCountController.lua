local local_class = newclass('TowerBossEnemyCountController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- initialize data
	self.start = false
	self.current_count = 0

	-- parse data
	local stage_battle_info = require('stageeventcontrollers/TowerBossEnemyCountData.lua')
	self.current_stage_info = stage_battle_info[stage.Name]

	self.get_custom_sprite = function()
		return unity_object_pool.GetOrCreate('custom_sprite')
	end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate('custom_sprite')
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	if self.start == true then
		local new_count = self:get_monster_count()
		if self.current_count ~= new_count then
			self.current_count = new_count
			self:update_count_ui(new_count)
		end
	end
end

function local_class:get_monster_count()
	local count = 0

	local targets = stage.BattleManager:GetTargets(user_party.Leader)
	if targets ~= nil then
		count = targets.Count
		targets:Dispose()
	end

	return count
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))

	self:detach_count_ui()
	self:detach_image_ui()

	self.current_stage_info = nil
end

function local_class:on_stage_start_event(e)
	sp_util.play_normal_screenplay(field_ui_util.show_narration_async,
			{key = self.current_stage_info.description, parameters = {self.current_stage_info.enemy_limit}, stop_timer = true })
end

function local_class:on_battle_start_event(e)
	if self.start == false then
		self.start = true
		self.current_count = self:get_monster_count()
		self:attach_count_ui(self.current_count)
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attach_image_ui, self, user_party.Leader))
	end
end

function local_class:on_battle_end_event(e)
	self.start = false

	self:detach_count_ui()
	self:detach_image_ui()
end

function local_class:dead()
	--파티원이 리더에게 부여한 모든 버프를 지운다. (무적버프 대책)
	for i = 0, user_party.Count - 1 do
		buff_manager:RemoveBuff(user_party[i], CS.Oak.EquipmentSlot.None, user_party.Leader)
	end

	coroutine.yield(nil)

	local damage_info = CS.Oak.DamageInfo()
	damage_info.sender = user_party_leader
	damage_info.target = user_party_leader
	damage_info.type = CS.Oak.DamageType.Trap | CS.Oak.DamageType.Death
	damage_info.damage = CS.Oak.DamageConstants.InstantKillDamage

	local cmd = CS.Oak.DamageCommand.Create(damage_info)
	command_util.publish_cmd(damage_info.Owner, cmd)
end

-- 카운트 UI 시작하기 위해 붙임
function local_class:attach_count_ui(count)
	-- FIXME: 2.10에 X축 0 -> 0.25로 변경
	local target = user_party_leader
	local offset = vector(0, target.Bounds.size.y + 2, -0.5)
	self.count_ui = unity_object_pool.GetOrCreate('FieldUIDuelBuffState'):Instantiate(target.Position + offset,
			unity_class.quaternion.identity, target.Transform)

	self.count_ui.transform:Find('Offset').gameObject:SetActive(false)

	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = count
	tmp.color = unity_class.color.white
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

	if value >= self.current_stage_info.enemy_limit then
		self.start = false -- 중복처리 안하게 미리 끔
		tmp.color = unity_class.color.red
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.dead, self))
	elseif value >= self.current_stage_info.enemy_limit * 0.8 then
		tmp.color = unity_class.color.yellow
		--danger
	else
		tmp.color = unity_class.color.white
		--normal
	end
end

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
	local offset = vector(-0.45, target.Bounds.size.y + 1.6, -0.5)
	self.pooled_sprite = self.get_custom_sprite():Instantiate(target.Bounds.center + offset,
			unity_class.quaternion.identity, target.Transform)
	self.invader_sprite = self.pooled_sprite.transform:GetComponent(typeof(CS.CustomSprite))
	self.invader_sprite.transform.localRotation = unity_class.quaternion.Euler(45, 0, 0)
	self.invader_sprite.transform.localScale = unity_class.vector3.one * 0.5
	self.invader_sprite.Atlas = custom_atlas

	self.invader_sprite.SpriteName = 'emoticon_bubble_invader.png'
	self.invader_sprite:Rebuild()
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

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
