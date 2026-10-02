local local_class = newclass("TowerPeriodicalBuffController")

-- 특정 시간 초마다 특정 버프를 켜주고 꺼주를 반복해주는 버프 컨트롤러
function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	local buff_infos = require('stageeventcontrollers/TowerPeriodicalBuffData.lua')


	-- 진입한 스테이지에 따른 버프 데이터 파싱
	local stage_name = stage.Name
	self.gimmick_started = false
	self.current_stage_buff_info = buff_infos[stage_name]
	self.character_buff_table = self:parse_buff_data()
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	-- 초기에 모든 버프를 꺼줌.
	self:preload_resources()
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

function local_class:preload_resources()
	for target_name, buff_table in pairs(self.character_buff_table) do
		for idx, buff_data in ipairs(buff_table) do
			if buff_data.effect_pool ~= nil then
				unity_object_pool.GetOrCreate(buff_data.effect_pool)
			end
		end
	end
end

-- 전투 시작할 때 들어간 존이 미리 설정된 배틀 그룹명과 같은지.
function local_class:entered_effective_zone(e)
	local zone_name = e.Zone.Name

	for i = 1, #self.current_stage_buff_info do
		local battle_group_name = self.current_stage_buff_info[i].battle_group
		if battle_group_name == zone_name then
			return true
		end
	end

	return false
end


-- 전투 시작시
function local_class:on_zone_enter_event(e)
	if self.gimmick_started then return end
	if e.FieldObject ~= user_party.Leader and not e.FullEnter then return end
	if not self:entered_effective_zone(e) then return end

	self.gimmick_started = true
	local triggered_event = util.cs_generator(self.begin_count_down, self, e.Zone.Name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, triggered_event)
end

function local_class:begin_count_down(zone_name)
	-- 캐릭터당 들고 있는 버프 리스트들 실행
	for target_name, buff_table in pairs(self.character_buff_table) do
		if (buff_table.battle_group == zone_name) then
			local triggered_event = util.cs_generator(self.repeat_apply_withdraw, self, target_name, buff_table)
			coroutine_manager:StartCoroutine(stage.StageGameObject, triggered_event)
		end
	end
end

-- 일정 간격으로 버프를 키고, 끄고 반복하는 루틴.
function local_class:repeat_apply_withdraw(target_name, buff_table)
	local cool_time = buff_table.initial_waiting_duration
	local activation_duration = buff_table.activation_duration
	local target = get_character(target_name)
	local buff_count = buff_table.buff_count
	local idx = 1

	while true do
		-- 해당 캐릭터가 필드 내에 존재해야함.
		if target == nil then return end
		cool_time = cool_time - unity_class.time.deltaTime

		if cool_time <= 0 then
			self:activate_buff_for_seconds(target, buff_table[idx], activation_duration)
			idx = (idx >= buff_count) and 1 or idx + 1
			cool_time = buff_table.waiting_duration - activation_duration
		end

		coroutine.yield(nil)
	end
end

function local_class:activate_buff_for_seconds(target, buff_data, activation_duration)
	-- 실행 후 일정 시간이 지나면 버프를 해제하는 루틴

	local buff_spec_name = buff_data.buff_spec_name
	buff_manager:AddBuff(target, CS.Oak.EquipmentSlot.None, target, buff_spec_name, 0, false, false)

	local effect_pool = unity_object_pool.GetOrCreate(buff_data.effect_pool)
	local target_scale = (target.Hitbox.size.x > 1) and target.Hitbox.size.x or 1
	local pooled_effect = effect_pool:Instantiate(target.Position, unity_class.quaternion.identity, target.transform)
	pooled_effect.transform.localScale = unity_class.vector3(target_scale, 1, target_scale)

	wait_for_sec(activation_duration)
	buff_manager:RemoveBuff(target, CS.Oak.EquipmentSlot.None, target, buff_spec_name)
	pooled_effect:Dispose()
end

-- 스테이지별로 미리 세팅된 버프 데이터를 파싱해서 컨트롤러에서 쓰기 쉽도록 정리해줌.
function local_class:parse_buff_data()
	local character_buff_table = {}

	for _, value in ipairs(self.current_stage_buff_info) do
		local target_name = value.target_name

		for __, buff in ipairs(value.buff) do
			local buff_table = {
				buff_spec_name = buff.buff_spec_name,
				effect_pool = buff.effect_pool,
			}

			if character_buff_table[target_name] == nil then
				character_buff_table[target_name] = {}
			end

			table.insert(character_buff_table[target_name], buff_table)
		end
		character_buff_table[target_name].initial_waiting_duration = value.initial_waiting_duration
		character_buff_table[target_name].waiting_duration = value.waiting_duration
		character_buff_table[target_name].activation_duration = value.activation_duration
		character_buff_table[target_name].battle_group = value.battle_group
		character_buff_table[target_name].buff_count = #character_buff_table[target_name]
	end

	return character_buff_table
end

-- 주어진 option id에 맞는 버프를 캐릭터로부터 찾아 반환, 없으면 nil을 반환.
function local_class:find_matched_buff(target, option_id)
	local stage_options = target.FieldObjectBehaviour.StageOptions

	for i = 0, stage_options.Count - 1 do
		if stage_options[i].Option.Id == option_id then
			return stage_options[i]
		end
	end

	return nil
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.character_buff_table = nil
	self.buff_infos = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
