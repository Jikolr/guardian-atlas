local local_class = newclass('TowerDestroyedCountdownController')
-- TowerHitStackBuffOption 참고

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
	}

	-- 해당 컨트롤러에 필요한 데이터 셋 불러오기.
	self.stage_battle_info = require('stageeventcontrollers/TowerDestroyedCountdownData.lua')

	self.current_stack_count = 0
	self.gagoyles = nil
	self.gagoyle_effect = nil
	self.gagoyle_sfx_info = nil
	self.play_sfx = false
	self.debuff_data = nil
	self.count_ui = nil
	self.current_stage_info = nil
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start')
	message_system:Subscribe(self, typeof(CS.Oak.BossSapaLeaderExplodeSpritBombEvent), 'on_explode_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]

	self.gagoyles = {}
	for _,v in pairs(self.current_stage_info.gagoyle_names) do
		local fo = get_field_object(v)
		if not is_unity_null(fo) then
			table.insert(self.gagoyles, fo)
		end
	end
	self.current_stack_count = #self.gagoyles

	self.debuff_data = self.current_stage_info.debuff_data

	-- 효과음 로드
	if self.current_stage_info.gagoyle_sfx ~= nil then
		self.gagoyle_sfx_info = CS.Oak.SfxInfo()
		self.gagoyle_sfx_info.sfxName = self.current_stage_info.gagoyle_sfx
		self.gagoyle_sfx_info.loop = false
		self.gagoyle_sfx_info.typePriority = CS.Oak.SfxTypePriority.Gimmick

		music_player:PreloadSfx(self.gagoyle_sfx_info.sfxName)
		self.play_sfx = true
	end

	local effect_pool_name = self.current_stage_info.gagoyle_effect
	if effect_pool_name ~= nil then
		self.gagoyle_effect = unity_object_pool.GetOrCreate(effect_pool_name)
	else
		self.gagoyle_effect = nil
	end

	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start(e)
	sp_util.play_normal_screenplay(field_ui_util.show_narration_async,
			{key = self.current_stage_info.description, parameters = {self.current_stack_count}, stop_timer = true })
end

function local_class:on_battle_start_event(e)
	self.current_progress = self.progress.playing

	self:attach_count_ui(self.current_stack_count)
	self:update_buff()
end

function local_class:on_battle_end_event(e)
	self.current_progress = self.progress.none

	self:detach_count_ui()
	self:remove_buff()
end

function local_class:on_explode_event(e)
	if self.current_progress ~= self.progress.playing then return end

	local destroy_flag = false
	for i = #self.gagoyles, 1, -1 do
		-- 폭발 범위 안에 있는지 체크
		if vector_util.get_x0z(e.Position - self.gagoyles[i].Position).sqrMagnitude <= (e.Radius * e.Radius) then
			local destroyed_obj = self.gagoyles[i]

			character_util.set_active_state(destroyed_obj, 'disabled')
			if not is_unity_null(self.gagoyle_effect) then
				self.gagoyle_effect:Instantiate(destroyed_obj.Position)
			end
			if self.play_sfx then
				self.gagoyle_sfx_info.playPosition = destroyed_obj.Position
				music_player:PlaySfx(self.gagoyle_sfx_info)
			end

			table.remove(self.gagoyles, i)
			self.current_stack_count = self.current_stack_count - 1
			destroy_flag = true
		end
	end

	-- 여러번 버프를 부여하지 않기 위해 석상이 1개 이상 파괴된 경우 버프 재부여
	if destroy_flag then
		self:be_destroy()
	end
end

function local_class:be_destroy()
	self:update_count_ui(self.current_stack_count)

	if self.current_stack_count < 1 then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.dead, self))
	else
		self:update_buff()
	end
end

function local_class:update_buff()
	if self.current_stack_count <= 0 then return end

	for i = 0, user_party.Count - 1 do
		local member = user_party[i]

		for _, debuff_info in ipairs(self.debuff_data) do
			local debuff_id = debuff_info[1]
			local debuff_level = debuff_info[2]

			--기존 버프 해제
			buff_manager:RemoveBuff(member, CS.Oak.EquipmentSlot.None, member, debuff_id)
			-- 새 버프 설정 (가고일 석상 수 * 레벨 기본값)
			buff_manager:AddBuff(member, CS.Oak.EquipmentSlot.None, member, debuff_id,
					self.current_stack_count * debuff_level, false, false)
		end
	end
end

function local_class:remove_buff()
	for i = 0, user_party.Count - 1 do
		local member = user_party[i]

		for _, debuff_info in ipairs(self.debuff_data) do
			local debuff_id = debuff_info[1]

			--기존 버프 해제
			buff_manager:RemoveBuff(member, CS.Oak.EquipmentSlot.None, member, debuff_id)
		end
	end
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

	self.current_progress = self.progress.none
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

	if value >= 3 then
	elseif value >= 2 then
		tmp.color = unity_class.color.yellow
	else
		tmp.color = unity_class.color.red
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BossSapaLeaderExplodeSpritBombEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))

	self.cs_controller = nil
	self.stage_battle_info = nil
	self.current_stage_info = nil

	self.debuff_data = nil
	self.gagoyles = nil
	self.gagoyle_sfx_info = nil
	self.play_sfx = nil
	self.gagoyle_effect = nil
	self.current_stack_count = nil
	self.count_ui = nil
	self.current_progress = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
