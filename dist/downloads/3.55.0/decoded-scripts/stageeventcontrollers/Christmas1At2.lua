local local_class = newclass("Christmas1At2Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 이벤트 존 이름
	self.gimmick_area_event_zone_name = 'gimmick_area'

	-- 캐릭터를 가져오는 함수
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		end

		return get_character('knight_female')
	end

	-- 오브젝트를 가져오는 함수
	self.get_invader_ship = function(num) return get_field_object('invader_ship_' .. num) end
	self.get_door = function() return get_field_object('airplane_door') end
	self.get_wall = function() return get_field_object('airplane_wall') end
	self.get_wing = function() return get_field_object('airplane_wing') end
	self.get_tail = function() return get_field_object('airplane_tail') end

	-- 퍼플코인을 가져오는 함수
	self.get_purple_coin = function(num) return get_field_object('purple_coin_' .. num) end

	-- 이펙트 오브젝트 풀을 가져오는 함수
	self.get_windhole_effect = function() return unity_object_pool.GetOrCreate('fx_xmas_airplane_windhole') end
	self.get_windhole_side_effect = function() return unity_object_pool.GetOrCreate('fx_xmas_airplane_windhole_side') end
	self.get_windhole_side_small_effect = function() return unity_object_pool.GetOrCreate('fx_xmas_airplane_windhole_side_small') end

	-- 인베이더 전함 갯수
	self.invader_ship_num = 8

	-- 틴트 키
	self.tint_key_1 = 'tint_key_1'
	self.tint_key_2 = 'tint_key_2'

	-- sfx
	self.fire_sfx = nil

	-- effect
	self.windhole_effect_list = nil
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	self.get_windhole_effect()
	self.get_windhole_side_effect()
	self.get_windhole_side_small_effect()

	yield_return(unity_object_pool, 'WaitAll')
end

function local_class:need_on_launch()
	local christmas_main_quest_id = 60045
	local quest_progress = user_progress:GetStartedQuest(christmas_main_quest_id)
	local progress_list = {
		5,
		6
	}

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	end

	return true
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	if self.fire_sfx ~= nil then
		self.fire_sfx:Stop()
		self.fire_sfx = nil
	end

	if self.windhole_effect_list ~= nil then
		for i = 1, #self.windhole_effect_list do
			if self.windhole_effect_list[i] ~= nil then
				self.windhole_effect_list[i]:Dispose()
				self.windhole_effect_list[i] = nil
			end
		end

		self.windhole_effect_list = nil
	end

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		return self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		return self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	self:change_manual_character()

	for i = 1, self.invader_ship_num do
		local invader_ship = self.get_invader_ship(i)

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.invader_ship_hovering, self, invader_ship, (i - 1) * 0.2))
	end

	local christmas_main_quest_id = 60045
	local quest_progress = user_progress:GetStartedQuest(christmas_main_quest_id)
	-- 프로그레스가 6이 넘거나, 퀘스트를 클리어 했을 경우
	if quest_progress ~= nil and (quest_progress.InnerProgress > 6 or quest_progress.IsComplete) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.broken_airplane, self))

		self.fire_sfx = music_player_util.play_sfx({ sfx_name = '01_fire_03', loop = true, type_priority = 'event', player_priority = 'default' })

		self.windhole_effect_list = {}
		local windhole_effect = self.get_windhole_effect():Instantiate(vector(49, 0, 75.5), unity_class.quaternion.Euler(0, 180, 0), nil)
		table.insert(self.windhole_effect_list, windhole_effect)

		local wall = self.get_wall()
		windhole_effect = self.get_windhole_side_effect():Instantiate(wall.Position + vector(0.6, 0, 0), unity_class.quaternion.Euler(0, -90, 0), nil)
		table.insert(self.windhole_effect_list, windhole_effect)

		local door = self.get_door()
		windhole_effect = self.get_windhole_side_small_effect():Instantiate(door.Position, unity_class.quaternion.Euler(0, 90, 0), nil)
		table.insert(self.windhole_effect_list, windhole_effect)

		local default_start = field:GetMarker('default_start')
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			screen_util.fade_in_circular(1, 'linear')
			screen_util.fade_in(1, unity_class.color.black, 'linear')
			stage_launch_util.directional_stage_entry(default_start.position, default_start.direction, game_string:GetString(stage.Name), true, false)
		end))
	end

	self:invader_ship_attack(false)

	return true
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'invader_ship_attack_start' then
		self:invader_ship_attack(true)
		return true
	elseif e:GetParamAt(0) == 'invader_ship_attack_stop' then
		self:invader_ship_attack(false)
		return true
	end

	return false
end
--endregion

-- 파티 리더를 크리스마스 전용 기사로 변경한다.
function local_class:change_manual_character()
	local knight = self.get_knight()
	local param = CS.Oak.CharacterConvertParam:ManualDefault()

	param.HidePreviousParty = true
	character_util.convert_to_manual_character(knight, param, true)
end

-- 인베이더 전함이 둥둥 떠다니는 연출
function local_class:invader_ship_hovering(fo, delay)
	local time_passed = 0
	local speed = 0.25
	local height = 0.75
	local ship_position = fo.Position

	if delay ~= nil then
		wait_for_sec(delay)
	end

	while true do
		local y = unity_class.mathf.Sin(unity_class.mathf.PI * 2 * time_passed * speed) * height

		fo.Position = vector_util.get_x0z(ship_position, y)

		time_passed = time_passed + unity_class.time.deltaTime

		coroutine.yield()
	end
end

-- 인베이더 전함이 공격하는 연출
function local_class:invader_ship_attack(is_show)
	for i = 1, self.invader_ship_num do
		local invader_ship = self.get_invader_ship(i)
		local effect_object = invader_ship.transform:GetChild(0)

		effect_object.gameObject:SetActive(is_show)
	end
end

-- 부서져 있는 비행기
function local_class:broken_airplane()
	local door = self.get_door()
	local wing = self.get_wing()
	local tail = self.get_tail()

	door.ActiveState = active_state('disabled')
	self:airplane_wall_broken()
	self:active_fo_effect(wing)
	self:active_fo_effect(tail)

	self:disabled_all_gimmick()

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.tint_loop, self))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.camera_rotation, self))
end

-- 깜빡이는 틴트, 카메라 쉐이크
function local_class:tint_loop()
	local duration = 2

	field:Tint(self.tint_key_1, unity_color({ 1, 0.6, 0.6, 1 }), 0)

	while true do
		camera_util.shake(0.08, duration * 0.7)
		field:Tint(self.tint_key_2, unity_color({1.0, 0.2, 0.2, 1}), duration)
		wait_for_sec(2.5)

		camera_util.shake(0.08, duration * 0.7)
		field:RemoveTint(self.tint_key_2, duration)
		wait_for_sec(2.5)
	end

	field:RemoveTint(self.tint_key_1, 0)
	field:RemoveTint(self.tint_key_2, 0)
end

-- 벽에 구멍이 뚫림
function local_class:airplane_wall_broken()
	local wall = self.get_wall()
	local mesh = wall.transform:GetChild(0)
	local none_fragment = mesh.transform:GetChild(0)
	local fragment = mesh.transform:GetChild(1)
	local none_fragment_renderers = none_fragment.gameObject:GetComponent(typeof(CS.UnityEngine.Renderer))
	local fragment_renderers = fragment.gameObject:GetComponent(typeof(CS.UnityEngine.Renderer))

	none_fragment.gameObject:SetActive(false)
	fragment.gameObject:SetActive(true)

	fragment_renderers.sharedMaterial = none_fragment_renderers.sharedMaterial
end

-- 해당 기믹 안에 있는 비활성화 된 effect 오브젝트를 활성화 시킨다.
function local_class:active_fo_effect(fo)
	local effect_object = fo.transform:Find('on')

	effect_object.gameObject:SetActive(true)
end

-- 카메라 회전
function local_class:camera_rotation()
	local rotate_angle = 45
	local rotate_angle_offset = 2.5
	local rotate_speed = 0.25
	local time_passed = 0

	local camera_pivot = stage_camera.Transform.parent

	while true do
		time_passed = time_passed + unity_class.time.deltaTime

		local sin_val = unity_class.mathf.Sin(2 * unity_class.mathf.PI * time_passed * rotate_speed)
		camera_pivot.transform.localRotation = unity_class.quaternion.AngleAxis(rotate_angle + (rotate_angle_offset * sin_val), vector(1, 0, 0))

		coroutine.yield()
	end
end

-- 이벤트 존 안에 있는 모든 기믹들을 비활성화
function local_class:disabled_all_gimmick()
	local target_zone = field:GetZone(self.gimmick_area_event_zone_name)
	local gimmick_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(target_zone.Bounds, unity_class.vector3.zero)

	for i = 0, gimmick_list.Count - 1 do
		local gimmick = gimmick_list[i]

		gimmick.ActiveState = active_state('disabled')
	end

	gimmick_list:Dispose()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
