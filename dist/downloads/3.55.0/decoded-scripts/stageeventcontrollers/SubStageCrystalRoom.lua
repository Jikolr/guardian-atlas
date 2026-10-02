local local_class = newclass("SubStageCrystalRoom")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.data_storage = nil

	-- 배터리 소켓
	self.get_crystal_socket = function(num) return get_field_object('crystal_socket_'..num) end

	-- 배터리 데이터 키(절대 변경 불가)
	self.crystal_key = 'crystal'

	-- 배터리 보유 여부 확인용 변수
	-- 북동남서 시계방향대로 1 2 4 8
	self.has_crystal = {
		none = 0,
		up = 1,
		right = 2,
		down = 4,
		left = 8,
		all = 15
	}

	-- 배터리 장착 데이터 키(절대 변경 불가)
	self.equip_crystal_key = 'equip_crystal'

	-- 배터리 장착 여부 확인용 변수
	-- 북동남서 시계방향대로 1 2 4 8
	self.equip_crystal = {
		none = 0,
		up = 1,
		right = 2,
		down = 4,
		left = 8,
		all = 15
	}

	-- 15챕터 퀘스트 id 해당 퀘스트가 클리어됐을 경우 모든 크리스탈 장착
	self.queen_ship_main_quest_id = 311
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local demon_world_dollar = get_or_create_global_table('stageeventcontrollers/DemonWorldDollar')
	yield_return_func(demon_world_dollar.load_resource, demon_world_dollar)

	local storage_create = require('utils/QuestDataStorage')
	self.data_storage = storage_create.create(221)
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	local quest_id = 239
	if user_progress:ClearedQuest(quest_id) then
		sp_util.play_normal_screenplay(self.opening_routine, self)
	end

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	self.data_storage = nil

	self.cs_controller = nil
end

--region on event
function local_class:on_event(e)
	return false
end

function local_class:on_interact_event(e)
	for i = 1, 4 do
		if lua_helper.reference_equals(e.Target, self.get_crystal_socket(i))  then
			sp_util.play_normal_screenplay(self.interact_crystal_socket, self, i)
			return true
		end
	end

	return false
end

function local_class:on_stage_start_event(e)
	return false
end
--endregion on event
function local_class:opening_routine()
	self:setting_equip_crystal()

	--리더 캐릭터 복구
	local leader = user_party_leader
	character_util.set_position(leader, vector(-0.5, 8, 2.5))
	camera_util.move(leader.Position + vector(0, -7, 0), 0)

	self.resholder = CS.Foundations.ResourceHolder()

	local sphere = nil
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'effects/prologue_throneroom_effects', 'FX_teleportsphere_red', function(prefab)
				sphere = CS.UnityEngine.GameObject.Instantiate(prefab)
				sphere.transform:SetParent(effect_parent)
				sphere:SetActive(false)
			end)

	for i = 1, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 0, 0)
		character_util.set_active_state(user_party[i], 'disabled')
	end

	field:Tint(nil, CS.UnityEngine.Color(0.23, 0.23, 0.33, 0.3), 0)

	wait_for_sec(1)

	local stage_sfx = music_player_util.play_sfx({ sfx_name = '01_event_dw_11', loop = true, fade_in_time = 2 })
	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular_async(1, 'linear')

	sphere.transform:SetParent(leader.Transform)
	sphere.transform.localPosition = vector(0, 0.5, 0)
	sphere.transform.localRotation = unity_class.quaternion.Euler(-35, 0, 0)
	sphere:SetActive(true)

	local fall_time = 2.5
	local cur_time = unity_class.time.time
	local start_pos = leader.Position
	local end_pos = vector(start_pos.x, 0.2, start_pos.z)
	local free_fall = CS.CalculatorFreeFall(fall_time, start_pos.y, 0)

	local dir_change_time = 0
	local dir_time = 0.1
	local dir_str = {'left', 'up', 'right', 'down'}
	local dir_counter = 1

	local portal_sfx = music_player_util.play_sfx({ sfx_name = '01_portal_05'})
	while unity_class.time.time - cur_time < fall_time do
		free_fall:Proceed(unity_class.time.deltaTime)
		local cur_y = free_fall:GetDistance() + 0.2

		character_util.set_position(leader, start_pos + vector(0, cur_y, 0), true)

		if unity_class.time.time - cur_time >= dir_change_time then
			dir_change_time = dir_change_time + dir_time
			dir_counter = dir_counter + 1 > 4 and 1 or dir_counter + 1
			character_util.set_direction(leader, dir_str[dir_counter])
		end

		coroutine.yield(nil)
	end
	portal_sfx:FadeOut(1.5)

	character_util.set_position(leader, end_pos, false)
	character_util.set_direction(leader, 'down')
	music_player_util.play_sfx_one_shot('01_teleport_01')

	sphere:SetActive(false)
	yield_return(nil)
	sphere:SetActive(true)
	wait_for_sec(0.5)
	sphere:SetActive(false)

	wait_for_sec(0.5)

	character_util.jump_move(leader, vector(-0.5, 0, 0.5), 3, 1, true)
	music_player_util.play_sfx_one_shot('01_land_01')

	for i = 1, user_party.Count - 1 do
		character_util.set_active_state(user_party[i], 'enabled')
		character_util.set_direction(user_party[i], 'right')
		character_util.set_position(user_party[i], leader.Position + vector(i * -0.2, 0, 0))
		character_util.spine_set_alpha_fade(user_party[i], 1, 0.5)
	end

	camera_util.move(leader.Position, 1, {end_target = leader})
	party_util.align_to_target(leader.Position + vector(1, 0, 0), 'left', 1)

	coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position + vector(0.5, 0, 0),
			field:GetMarker('default_start').direction, game_string:GetString(stage.Name)))

	if self.resholder ~= nil then
		self.resholder:Dispose()
		self.resholder = nil
	end
end

function local_class:interact_crystal_socket(number)

	local crystal_number = 1 << (number - 1)
	local equip_crystal_data = self.data_storage:get_data(self.equip_crystal_key)
	if equip_crystal_data < 0 then equip_crystal_data = 0 end

	-- 배터리가 장착된 경우
	if (crystal_number & equip_crystal_data) ~= 0 then
		field_ui_util.show_narration_async({ key = 'demonworld_crystal_room_39' })
		return
	end

	field_ui_util.show_narration_async({ key = 'demonworld_crystal_room_32' })
	--용도를 알 수 없는 고대의 장치다
	field_ui_util.show_narration_async({ key = 'demonworld_crystal_room_33' })
	--마치 배터리 슬롯을 연상케 하는 빈 공간이 있다.

	local crystal_data = self.data_storage:get_data(self.crystal_key)
	if crystal_data < 0 then crystal_data = 0 end

	-- 해당 슬롯의 배터리를 소지중인 경우
	if (crystal_number & crystal_data) ~= 0 then
		-- 장착할 건지 나레이션
		field_ui_util.show_narration_async({ key = 'demonworld_crystal_room_35' })

		-- 장착 선택지
		local choose_result = choose_util.play_choose_event({
			{ 'demonworld_crystal_room_36', 'intellect' }, { 'demonworld_crystal_room_37', 'normal' } })

		-- 배터리 장착
		if choose_result == 1 then
			self.data_storage:set_data(self.equip_crystal_key, equip_crystal_data | crystal_number)
			local crystal = self.get_crystal_socket(number)
			local animator = crystal:GetComponent(typeof(CS.UnityEngine.Animator))
			animator:Play('open')
			music_player_util.play_sfx_one_shot('01_battery_02')
			wait_for_sec(2)
			music_player_util.play_sfx_one_shot('01_battery_01')
			wait_for_sec(1.5)
			field_ui_util.show_narration_async({ key = 'demonworld_crystal_room_38' })
		end
	end

	--region 새로운 배터리를 얻을 때 적용할 코드
	--local storage_create = require('utils/QuestDataStorage')
	--local data_storage = storage_create.create(221)
	--local crystal_data = data_storage:get_data('crystal')
	--if crystal_data == -1 then crystal_data = 0 end
	--local input_crystal_number = 1 -- 1, 2, 4, 8로 들어갈 예정
	--data_storage:set_data_async('crystal', crystal_data | input_crystal_number)
	--endregion
end

-- 배터리 세팅
function local_class:setting_equip_crystal()
	self:queen_ship_main_clear_check()

	local equip_crystal_data = self.data_storage:get_data(self.equip_crystal_key)
	if equip_crystal_data < 0 then equip_crystal_data = 0 end

	local crystal_number = self.equip_crystal.up

	-- 순회하면서 배터리 장착여부 확인
	while 1 << (crystal_number - 1) < self.equip_crystal.all do
		-- 장착된 배터리들 애니메이션 변경
		if (1 << (crystal_number - 1) & equip_crystal_data) ~= 0 then
			local crystal = self.get_crystal_socket(crystal_number)
			local animator = crystal:GetComponent(typeof(CS.UnityEngine.Animator))
			animator:Play('idle')
		end
		crystal_number = crystal_number + 1
	end
end

function local_class:queen_ship_main_clear_check()
	local quest_progress = user_progress:GetStartedQuest(self.queen_ship_main_quest_id)

	if quest_progress ~= nil and quest_progress.IsComplete then
		self.data_storage:set_data_async(self.crystal_key, self.has_crystal.all)
		self.data_storage:set_data_async(self.equip_crystal_key, self.equip_crystal.all)
	end
end

function local_class:stage_clear()
	music_player_util.play_sfx_one_shot('01_stage_in_teleport_01')
	screen_util.fade_out_circular_async(0.5, 'linear')
	CS.Oak.Game.Instance:StageToWorldmap(nil, stage.Name, nil, true, nil)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
