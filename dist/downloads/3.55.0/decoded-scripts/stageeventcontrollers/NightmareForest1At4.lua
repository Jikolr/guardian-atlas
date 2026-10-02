local local_class = newclass("NightmareForest1At4Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 스테이지에 존재하는 무덤 개수
	self.graves_count = 8
	-- 무덤 이름 prefix
	self.grave_name_prefix = 'grave_pushable_'

	self.is_interacting = false
	self.is_talked_ghost = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	-- 무덤 이펙트 제어용
	self.grave_effect_controller = {}

	self.light_on_preset = unity_object_pool.GetOrCreate('fx_obj_grave_aura_switch_on')
	self.grave_off_preset = unity_object_pool.GetOrCreate('fx_obj_grave_aura_switch_off')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	-- 이펙트 제어 용 table 비우기
	for key, value in pairs(self.grave_effect_controller) do
		if value ~= nil then
			value:Dispose()
			self.grave_effect_controller[key] = nil
		end
	end
	self.grave_effect_controller = nil

	self.light_on_preset = nil
	self.light_off_preset = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		return self:check_interact_object(e.Target)
	end

	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end
		local zone_name = e.Zone.Name

		if zone_name == 'ghost_talk' and not self.is_talked_ghost then
			self.is_talked_ghost = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ghost_talk, self))
			return true
		end
	end

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:stage_loaded()
		return true
	end

	return false
end

function local_class:stage_loaded()
	local grave_door = get_field_object('grave_door')
	if not grave_door.FieldObjectBehaviour.IsOpen then
		for index = 0, self.graves_count do
			local grave = get_field_object(self.grave_name_prefix .. index)

			if grave ~= nil then
				grave.Interactable = CS.Oak.PublishInteractable.Create()
			end
		end

		-- 1과 3 위치의 무덤은 퍼즐에 필요한 초기 세팅으로 켜져 있어야 함
		self:grave_effect_control_routine(1, true)
		self:grave_effect_control_routine(3, true)
	else
		-- 문이 열려 있으면 이펙트 전부 킴
		for i = 0, self.graves_count do
			self:grave_effect_control_routine(i, true)
		end
	end
end

function local_class:ghost_talk()
	local ghost_female = get_character("ghost_guard_female")
	local ghost_male = get_character("ghost_guard_male")

	speech_bubble_util.show_speech_bubble_async(ghost_female, { key = 'nightmare_forest_4_1' })

	speech_bubble_util.show_speech_bubble_async(ghost_male, { key = 'nightmare_forest_4_2' })

	ghost_female.Interactable.Talk = 'nightmare_forest_4_1'
	ghost_male.Interactable.Talk = 'nightmare_forest_4_2'
end

function local_class:check_interact_object(field_object)
	-- 현재 상호작용하는 객체가 있으면 이 루틴을 타지 않도록
	if self.is_interacting then
		return false
	end

	-- 대상 오브젝트 찾기
	for index = 0, self.graves_count do
		local grave = get_field_object(self.grave_name_prefix .. index)

		if grave ~= nil and lua_helper.reference_equals(grave, field_object) then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.light_out_routine, self, index))
			return true
		end
	end

	return false
end

function local_class:light_out_routine(index)
	-- 한 줄에 존재하는 무덤 개수
	local number = 3

	-- 동시에 다른 상호작용이 불가능 하도록
	self.is_interacting = true

	-- 호출하는 루틴에서 해당 index 오브젝트가 실제로 존재하는지 체킹하므로 계산 결과인 index 넘겨도 됨
	self:grave_effect_control_routine(index)
	self:grave_effect_control_routine(index - number)
	self:grave_effect_control_routine(index + number)

	-- 가장 왼쪽일 경우 체킹
	if index % number ~= 0 then
		self:grave_effect_control_routine(index - 1)
	end

	-- 가장 오른쪽일 경우 체킹
	if index % number ~= number - 1 then
		self:grave_effect_control_routine(index + 1)
	end

	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 라이트 아웃 퍼즐이 클리어 되었는가
	self:light_out_puzzle_check()

	self.is_interacting = false
end

-- 라이트 아웃 퍼즐 이펙트 제어
function local_class:grave_effect_control_routine(index, mute_sfx)
	local field_object = get_field_object(self.grave_name_prefix .. index)

	-- nil 체크
	if field_object == nil then
		return
	end

	local target_pos = field_object.Position

	-- 이펙트가 존재 할 때
	if self.grave_effect_controller[field_object] ~= nil then
		-- 사라지는 이펙트 생성
		object_pool_extensions.Instantiate(self.grave_off_preset, target_pos, unity_class.vector3.back)

		-- 기존 이펙트 dispose
		self.grave_effect_controller[field_object]:Dispose()
		self.grave_effect_controller[field_object] = nil

		-- 이펙트가 존재 하지 않을 때
	else
		-- 무덤의 불길한 기운 켜지는 이펙트 생성
		local effect = object_pool_extensions.Instantiate(self.light_on_preset, target_pos, unity_class.vector3.back)

		if not mute_sfx then
			-- 이펙트 sfx 재생
			music_player_util.play_sfx({
				sfx_name = '01_grave_aura_01', play_pos = target_pos, type_priority = 'default', player_priority = 'default'
			})
		end

		self.grave_effect_controller[field_object] = effect
	end
end

-- 라이트 아웃 퍼즐이 클리어 되었는지 체킹
function local_class:light_out_puzzle_check()
	-- 이펙트 전부 켜지면 클리어
	for index = 0, self.graves_count do
		local grave = get_field_object(self.grave_name_prefix .. index)

		if grave ~= nil then
			-- 하나라도 이펙트가 켜져 있지 않으면
			if self.grave_effect_controller[grave] == nil then
				return
			end
		end
	end

	-- 퍼즐 클리어 sfx
	music_player:PlaySfxOneShot('03_gimmick_jingle_01')

	for key in pairs(self.grave_effect_controller) do
		key.Interactable = CS.Oak.NonInteractable.Instance
	end

	message_system:Publish(CS.Oak.DoorOpenEvent.Create('grave_door', false))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
