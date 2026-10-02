local local_class = newclass("Christmas1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 리소스 홀더
	self.resholder = CS.Foundations.ResourceHolder()

	self.snow_screen_effect = nil

	-- FX 틴트 예외처리용 원본 컬러 저장
	self.cached_colors = {}

	-- 공장 내부인지 저장
	self.is_enter_factory = false

	-- 플레이어가 필살기 사용 중인지 저장
	self.is_super_attack = false

	-- 타일맵 존 이름
	self.factory_zone_name = 'factory'

	-- 틴트 키
	self.tint_key = 'christmas_1_1'

	-- 커스텀 이벤트 이름
	self.activate_snow_custom_event = 'activate_snow'
	self.deactivate_snow_custom_event = 'deactivate_snow'
	self.recover_fx_tint = 'recover_fx_tint'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	-- FX 레이어 틴트 예외처리
	local fx_layer = stage.StageTransform:Find(string.format('%s/fx', stage.Name))
	local renderers = fx_layer:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))

	for i = 0, renderers.Length - 1 do
		local renderer = renderers[i]

		local color
		if renderer.sharedMaterial:HasProperty("_Color") then
			color = renderer.sharedMaterial:GetColor("_Color")
		elseif renderer.sharedMaterial:HasProperty("_TintColor") then
			color = renderer.sharedMaterial:GetColor("_TintColor")
		else
			CS.UnityEngine.Debug.LogError('can not found light color')
		end

		table.insert(self.cached_colors, color * 0.83333)
	end

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	-- 이펙트 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/xmas/effects', 'fx_xmas_stage_snow_camera_fx', function(prefab)
				self.snow_screen_effect = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.snow_screen_effect.transform:SetParent(stage_camera.Transform.parent)
				self.snow_screen_effect.transform.localPosition = unity_class.vector3.zero
				self.snow_screen_effect.transform.localRotation = unity_class.quaternion.Euler(unity_class.vector3.zero)
			end)

	local main_quest_id = 60045
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	if main_quest == nil or main_quest.InnerProgress == 0 then
		self:deactivate_snow_effect()
	end

	-- 밤 틴트
	field:Tint(self.tint_key, CS.UnityEngine.Color(0.3, 0.3, 0.6, 0.8), 0)

	coroutine.yield(nil)

	local fx_layer = stage.StageTransform:Find(string.format('%s/fx', stage.Name))
	local renderers = fx_layer:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))

	for i = 0, renderers.Length - 1 do
		local renderer = renderers[i]

		if renderer.sharedMaterial:HasProperty("_Color") then
			renderer.sharedMaterial:SetColor("_Color", self.cached_colors[i + 1])
		elseif renderer.sharedMaterial:HasProperty("_TintColor") then
			renderer.sharedMaterial:SetColor("_TintColor", self.cached_colors[i + 1])
		end
	end
end

function local_class:need_on_launch()
	local christmas_main_quest_id = 60045
	local quest_progress = user_progress:GetStartedQuest(christmas_main_quest_id)
	local progress_list = {
		0,
		1
	}

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	end

	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)

	local christmas_main_quest_id = 60045
	local quest_progress = user_progress:GetStartedQuest(christmas_main_quest_id)

	if quest_progress ~= nil and not quest_progress.IsComplete and quest_progress.InnerProgress == 4 then
		-- 모든 파티원들을 파티에서 제외시키고, 비활성화 함.
		for i = user_party.Count - 1, 1, -1 do
			local party = user_party[i]

			character_util.convert_to_npc(party)
			character_util.set_active_state(party, 'disabled')
		end
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	if self.snow_screen_effect ~= nil then
		CS.UnityEngine.Object.Destroy(self.snow_screen_effect)
		self.snow_screen_effect = nil
	end

	if self.resholder ~= nil then
		self.resholder:Dispose()
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.check_player_super_action, self))
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return	end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	if zone_name == self.factory_zone_name then
		if not self.is_enter_factory then
			self.is_enter_factory = true

			self:enter_factory_event()
		end
	end
end

function local_class:on_zone_leave_event(e)
	if not e.FullLeave then return end
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end
	local zone_name = e.Zone.Name

	if zone_name == self.factory_zone_name then
		if self.is_enter_factory then
			self.is_enter_factory = false

			self:leave_factory_event()
		end
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.deactivate_snow_custom_event then
			self:deactivate_snow_effect()
		elseif e.Params[0] == self.activate_snow_custom_event then
			self:activate_snow_effect()
		elseif e.Params[0] == self.recover_fx_tint then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.recover_tint_fx_layer, self, 1))
		end
	end
end

-- 기사의 리베라 무기 스킬이 화면을 틴트시키므로 기사가 필살기를 사용할 때마다 fx 타일의 틴트를 복구시켜야 함
function local_class:check_player_super_action()
	local super_battle_action = CS.Oak.LuaBattleExtensions.GetBattleActionByName(user_party_leader, "CwpKnightThunderStrike")

	if super_battle_action == nil then
		return
	end

	while true do
		if not self.is_super_attack then
			if CS.Oak.LuaBattleExtensions.BattleActionIsActive(super_battle_action) then
				self.is_super_attack = true
			end
		else
			if not CS.Oak.LuaBattleExtensions.BattleActionIsActive(super_battle_action) then
				coroutine.yield(self:wait_for_super_action())
			end
		end

		coroutine.yield(nil)
	end
end

-- 리베라 무기 스킬이 지속되는 동안 대기
function local_class:wait_for_super_action()
	wait_for_sec(1)

	coroutine.yield(self:recover_tint_fx_layer(0.3))

	self.is_super_attack = false
end

-- 공장으로 들어가면 나오는 이벤트
function local_class:enter_factory_event()
	self:deactivate_snow_effect()

	-- 틴트 복구
	field:RemoveTint(self.tint_key, 0)
end

-- 공장을 벗어나면 나오는 이벤트
function local_class:leave_factory_event()
	self:activate_snow_effect()

	-- 밤 틴트
	field:Tint(self.tint_key, CS.UnityEngine.Color(0.3, 0.3, 0.6, 0.8), 0)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.remove_tint_fx_layer, self))
end

-- FX 레이어 틴트 예외처리
function local_class:remove_tint_fx_layer()
	-- 틴트 적용될 때까지 1프레임 대기
	coroutine.yield(nil)

	local fx_layer = stage.StageTransform:Find(string.format('%s/fx', stage.Name))
	local renderers = fx_layer:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))

	for i = 0, renderers.Length - 1 do
		local renderer = renderers[i]

		if renderer.sharedMaterial:HasProperty("_Color") then
			renderer.sharedMaterial:SetColor("_Color", self.cached_colors[i + 1])
		elseif renderer.sharedMaterial:HasProperty("_TintColor") then
			renderer.sharedMaterial:SetColor("_TintColor", self.cached_colors[i + 1])
		end
	end
end

-- FX 레이어 틴트 복구
function local_class:recover_tint_fx_layer(duration)
	local cur_time = unity_class.time.time
	local tint_duration = duration

	local fx_layer = stage.StageTransform:Find(string.format('%s/fx', stage.Name))
	local renderers = fx_layer:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))
	local cur_colors = {}

	for i = 0, renderers.Length - 1 do
		local renderer = renderers[i]

		local color
		if renderer.sharedMaterial:HasProperty("_Color") then
			color = renderer.sharedMaterial:GetColor("_Color")
		elseif renderer.sharedMaterial:HasProperty("_TintColor") then
			color = renderer.sharedMaterial:GetColor("_TintColor")
		else
			CS.UnityEngine.Debug.LogError('can not found light color')
		end

		table.insert(cur_colors, color)
	end

	while unity_class.time.time - cur_time < tint_duration do
		local normalized = (unity_class.time.time - cur_time) / tint_duration

		for i = 0, renderers.Length - 1 do
			local renderer = renderers[i]

			if renderer.sharedMaterial:HasProperty("_Color") then
				renderer.sharedMaterial:SetColor("_Color",
						unity_class.color.Lerp(cur_colors[i + 1], self.cached_colors[i + 1], normalized))
			elseif renderer.sharedMaterial:HasProperty("_TintColor") then
				renderer.sharedMaterial:SetColor("_TintColor",
						unity_class.color.Lerp(cur_colors[i + 1], self.cached_colors[i + 1], normalized))
			end
		end

		coroutine.yield(nil)
	end

	for i = 0, renderers.Length - 1 do
		local renderer = renderers[i]

		if renderer.sharedMaterial:HasProperty("_Color") then
			renderer.sharedMaterial:SetColor("_Color", self.cached_colors[i + 1])
		elseif renderer.sharedMaterial:HasProperty("_TintColor") then
			renderer.sharedMaterial:SetColor("_TintColor", self.cached_colors[i + 1])
		end
	end
end

-- 눈 이펙트 제거
function local_class:deactivate_snow_effect()
	-- 이펙트 비활성화
	self.snow_screen_effect:SetActive(false)
end

-- 눈 이펙트 활성화
function local_class:activate_snow_effect()
	-- 이펙트 활성화
	self.snow_screen_effect:SetActive(true)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
