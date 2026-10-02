demon_world_global_event = get_or_create_global_variable('utils/DemonWorldGlobalEvent')

local local_class = newclass("DemonWorldConvenienceStore")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 해당 컨트롤러에 필요한 데이터 로딩
	local stage_data = require('stageeventcontrollers/DemonWorldConvenienceStoreData.lua')

	self.string_key = 'demon_store_'
	self.decision_key = 'demon_store_choose_'

	-- 커스텀 아틀러스
	self.custom_atlas = nil

	-- 리소스 홀더
	self.res_holder = nil

	-- 힐 이펙트 FX
	-- 아이템 겟 FX
	self.item_get_fx = 'FX_item_get'
	-- 플레이어가 물건을 계속 들고 있는지.
	self.is_player_holding = false

	self.is_playing = true

	self.get_purchased_item = function() return get_field_object('purchased_item') end

	self.convenience_store_exit_prefix = 'convenience_store_item_exit'

	-- 현재 스테이지에서 사용되는 아이템 정보의 테이블
	self.item_table = stage_data[stage.Name].items
	-- 현재 스테이지에서 사용되는 출구들의 테이블
	self.exit_table = stage_data[stage.Name].item_exit
	-- 현재 스테이지에서 사용되는 입구들의 테이블
	self.entrance_table = stage_data[stage.Name].entrances

	-- 마계 달러 관련들
	self.data_storage = nil
	self.dollar_data_key = 'dollar'
	self.dollar_val = 0

	-- 상점 카메라 그리드 prefix
	self.cam_grid_prefix = 'store_camera_grid'

	-- 선반위에 있는 아이템들. 스테이지 나갈 시 Dispose 시켜줘야함.
	self.items_on_shelf = {}

	-- 4스테이지 예외처리
	self.stage_4_name = 'demonworld_part1_1_4'

	self.is_typing_end = false

	-- 나가는 연출 계속 생성되지 않도록 막는 방어코드
	self.is_leaving_store = false
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate('custom_sprite')
	unity_object_pool.GetOrCreate('FX_reset_object')
	yield_return(unity_object_pool, 'WaitAll')

	-- 커스텀 스프라이트용 아틀러스 준비
	if self.res_holder == nil then
		self.res_holder = CS.Foundations.ResourceHolder()

		coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName('spritesheets/items', 'items_custom'), function(prefab)
			self.custom_atlas = prefab.transform:GetComponent(typeof(CS.CustomAtlas))
			self.custom_atlas:Initialize()
		end))
	end

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	if self.get_purchased_item() ~= nil then
		message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_move_fo_event')
	end
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ActivateExitInteractableEvent), 'on_activate_exit_interactable_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.SpeechBubbleTypingEndEvent), 'on_typing_end_event')

	-- 마계 달러 저장소
	local storage_create = require('utils/QuestDataStorage')
	self.data_storage = storage_create.create(221)

	-- 마계 달러 잔액
	self.dollar_val = self.data_storage:get_data(self.dollar_data_key)

	-- 아이템 스프라이트 캐싱
	self.item_sprite = self:set_custom_sprite(vector(999, 0, 999), 'water')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	if self.get_purchased_item() ~= nil then
		message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))
	end
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ActivateExitInteractableEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SpeechBubbleTypingEndEvent))

	for i = 1, #self.items_on_shelf do
		if self.items_on_shelf[i] ~= nil then
			self.items_on_shelf[i]:ConsumeComplete()
		end
	end

	self.items_on_shelf = nil

	self.item_sprite:Dispose()
	self.item_sprite = nil
	self.item_table = nil
	self.exit_table = nil

	self.is_playing = false


	self.cs_controller = nil

end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return end

	if string.find(e.Zone.Name, self.convenience_store_exit_prefix)
			and not self.is_leaving_store
			and lua_helper.type_compare(user_party_leader.FieldObjectBehaviour.CurrentActionState, typeof(CS.Oak.CharacterHoldUpState))then
		self.is_leaving_store = true
		local exit_marker_name = self.exit_table[e.Zone.Name]
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.exit_store, self, exit_marker_name))
	end
end

function local_class:on_activate_exit_interactable_event(e)
	if e.IsActive then
		for _, door_name in ipairs(self.entrance_table) do
			local fo = get_field_object(door_name)
			if fo ~= nil then
				fo.ActiveState = CS.Oak.ActiveState.Enabled
			end
		end
	else
		for _, door_name in ipairs(self.entrance_table) do
			local fo = get_field_object(door_name)
			if fo ~= nil then
				fo.ActiveState = CS.Oak.ActiveState.Disabled
			end
		end
	end
end

function local_class:on_stage_start_event(e)
	self:set_item_sprites_on_shelf()
end

-- 편의점 카메라 그리드에 들어왔다면 편의점 배경음으로 바꾸어줘야한다.
-- 해당 기능을 사용하려면 타일맵에서 카메라 그리드에
-- 'store_camera_grid'를 prefix로 붙이자.
function local_class:on_camera_grid_enter_event(e)
	local entered_grid = e.CameraGrid
	local cam_grid_name = entered_grid.name

	if string.find(cam_grid_name, self.cam_grid_prefix) then
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { 'pause_car_logic' }))

		music_player_util.play_stage_music({ name = 'ondemand/v2_15_demonworld/audio:bgm_demonworld_store', state = 'event', mix = 1.2 })
		music_player_util.play_sfx_one_shot('01_interact_cakeshop_01')
	end
end

function local_class:on_typing_end_event(e)
	self.is_typing_end = true
end

function local_class:on_camera_grid_leave_event(e)
	local left_grid = e.CameraGrid
	local cam_grid_name = left_grid.name

	if string.find(cam_grid_name, self.cam_grid_prefix) then
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { 'resume_car_logic' }))

		if stage.Name ~= self.stage_4_name then
			music_player_util.play_stage_music({ name = 'ondemand/v2_15_demonworld/audio:bgm_demonworld_main', state = 'field', mix = 1.2 })
		else
			music_player_util.play_stage_music({ name = 'ondemand/v2_15_demonworld/audio:bgm_demonworld', state = 'field', mix = 1.2 })
		end
	end
end

function local_class:on_move_fo_event(e)
	local moved_object = e.FieldObject
	if lua_helper.reference_equals(moved_object, self.get_purchased_item()) then
		if self.item_sprite ~= nil then
			local is_holding = user_party.Leader.CharacterBehaviour.CurrentActionState ~= nil and
					lua_helper.type_compare(user_party.Leader.CharacterBehaviour.CurrentActionState, CS.Oak.CharacterHoldUpState)

			if (is_holding) then
				self.item_sprite.transform.localPosition = moved_object.Position + vector(0, 0, 0.1)
			else
				self.item_sprite.transform.localPosition = moved_object.Position + vector(0, 0.5, 0)
			end
		end
	end

	return false
end

function local_class:on_interact_event(e)
	local target = e.Target
	local item = nil
	local store_item_name = nil

	for name, data in pairs(self.item_table) do
		-- 이름이 들어가는 아이템이 있는지
		if string.find(target.Name, name) then
			item = data
			store_item_name = name
			break
		end
	end

	if item ~= nil then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.ask_to_purchase, self, target, item, store_item_name))
	end
end

function local_class:on_field_object_destroyed_event(e)
	local destroyed = e.FieldObject

	if lua_helper.reference_equals(self.get_purchased_item(), destroyed) then
		destroyed.Position  = vector(999, 0, 999)
	end
end

--region 컨트롤러 로직 관련
function local_class:ask_to_purchase(target, item, store_item_name)
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local price = item.price
	local description = self.string_key .. item.info.subtitle
	local name = game_string:GetString(self.string_key .. item.info.title)
	local override_desc = lua_helper.get_or_default(item.override_item_description, false)
	-- 아이템 설명문 표시

	if override_desc then
		local item_desc = game_string:GetString(description)
		local overriden_text = string.format("%s - %s.", name, item_desc)
		speech_bubble_util.show_speech_bubble_async(target, { key = overriden_text, skip = true })
	else
		speech_bubble_util.show_speech_bubble_async(target, { key = description, skip = true })
	end

	self.is_typing_end = false

	-- {0}를 소비해 {1}를 구입하시겠습니까?
	 speech_bubble_util.show_speech_bubble(target, {
			key = { self.string_key .. 'text_1', tostring(price), name },
			keep_display = true,
			skip = true
		})

	while not self.is_typing_end do
		coroutine.yield()
	end

	wait_for_sec(0.5)

	local result = choose_util.play_choose_event({
		-- 구매한다.
		{ self.decision_key .. 1, 'mercy' },
		-- 구매하지 않는다.
		{ self.decision_key .. 2, 'normal' }
	})

	speech_bubble_util.remove_bubble(target)

	if result == 1 then
		yield_return_func(self.purchase, self, target, item, store_item_name)
	end

	-- 리셋
	self.is_typing_end = false

	field_ui_manager:Show()
	party_util.reset_controllers()
end

function local_class:speech_bubble_helper(target, price, name)
	speech_bubble_util.show_speech_bubble_async(target, {
		key = { self.string_key .. 'text_1', tostring(price), name },
		keep_display = true,
		skip = true
	})
end

function local_class:purchase(target, item, item_name)
	-- 돈이 충분한지 확인
	local demon_world_dollar = get_or_create_global_table('stageeventcontrollers/DemonWorldDollar')
	if demon_world_dollar:get_dollar() < item.price then
		music_player:PlaySfxOneShot('01_hit_comic_01')

		speech_bubble_util.show_speech_bubble(target, { key = self.string_key .. 'text_2', skip = true })
		return
	end

	music_player:PlaySfxOneShot('03_get_drop_gold_01')

	local init_pos = target.transform.position
	local field_object = get_field_object('purchased_item')
	local sprite_info = item.sprite
	local is_holdable = item.holdable
	local is_edible = item.edible

	if is_holdable then
		field_object.ActiveState = CS.Oak.ActiveState.Disabled
		field_object.Transform.position = vector(999, 0, 999)

		-- 기존에 있었던 것은 지워줌.
		self.item_sprite:Dispose()
		self.item_sprite = self:set_custom_sprite(init_pos, sprite_info)

		if item.play_item_get then
			self:play_item_get(item.info.title, item.info.subtitle, item.info.desc)
		end

		field_object.ActiveState = CS.Oak.ActiveState.Enabled
		command_util.execute_holdup(user_party_leader, field_object, user_party_leader.Position)
	elseif is_edible then
		yield_return_func(self.consume_item_routine, self, item, item_name, init_pos)
	else
		local drop_item = self:generate_store_item_as_drop_item(item.id, 'dontfindlooter',
				init_pos + vector(0.1, 1.5, -0.3))
		drop_item.ConsumeTarget = user_party_leader

		if item.play_item_get then
			wait_for_sec(1)
			self:play_item_get(item.info.title, item.info.subtitle, item.info.desc)
		end
	end

	if item.should_store then
		self:save_item_purchase_info(item_name, 1)
	end

	demon_world_dollar:remove_dollar(item.price, false, { play_sfx = false })

	message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { 'item_purchased', item_name }))
end

--- @summary : 이 메소드는 스테이지 시작과 동시에 코루틴으로 호출 되어 스테이지 종료 시에 꺼진다.
function local_class:update_custom_sprite()
	local field_object = get_field_object('purchased_item')

	while self.is_playing do
		if self.item_sprite ~= nil then
			local is_holding = user_party.Leader.CharacterBehaviour.CurrentActionState ~= nil and
					lua_helper.type_compare(user_party.Leader.CharacterBehaviour.CurrentActionState, CS.Oak.CharacterHoldUpState)

			if (is_holding) then
				self.item_sprite.transform.localPosition = field_object.Position + vector(0, 0, 0.1)
			else
				self.item_sprite.transform.localPosition = field_object.Position + vector(0, 0.5, 0)
			end
		end
		coroutine.yield(nil)
	end
end

function local_class:set_custom_sprite(pos, sprite)
	local item = unity_object_pool.GetOrCreate('custom_sprite'):Instantiate(pos)

	local custom_sprite = item:GetComponent(typeof(CS.CustomSprite))
	custom_sprite.transform.localRotation = unity_class.quaternion.Euler(vector(10, 0, 0))
	custom_sprite.transform.localScale = vector(1, 1, 1)
	custom_sprite.LocalScale = unity_class.vector2.one * 1.4
	custom_sprite.Atlas = self.custom_atlas
	custom_sprite.Alpha = 1
	custom_sprite.SpriteName = sprite

	custom_sprite:Rebuild()

	return item
end

function local_class:generate_store_item_as_drop_item(id, loot_state, pos_to_spawn)
	local item = drop_item_util.create_item(
			{ itemid = id, pos = pos_to_spawn, lootstate = loot_state, notforinven = true, sprscale = 0.929, showoncharacter = true })
	item.SpriteTransform.rotation = unity_class.quaternion.Euler(10, 0, 0)
	--item.SpriteTransform.localScale = vector(0.93, 0.9275, 0.9275)
	return item
end

function local_class:consume_item_routine(item, item_name, init_pos)
	local eat_sfx = music_player_util.play_sfx({ sfx_name = '01_eat_01' })
	character_util.set_anim(user_party_leader, { name = 'eat' })

	wait_for_sec(1)

	--self:generate_store_item_as_drop_item(item.id, 'dontfindlooter', init_pos + vector(0.1, 1.5, -0.335))
	local drop_item = self:generate_store_item_as_drop_item(item.id, 'dontfindlooter',
			init_pos + vector(0.1, 1.5, -0.3))
	drop_item.ConsumeTarget = user_party_leader

	wait_for_sec(0.5)

	music_player:PlaySfxOneShot('02_magic_heal_01')
	if item_name == 'store_sushi' then
		for i = 0, user_party.Count - 1 do
			-- 힐
			local heal_info = CS.Oak.HealInfo()
			heal_info.type = CS.Oak.HealType.Normal
			heal_info.heal = user_party[i].CharacterStatsBehaviour.MaxHP
			heal_info.isRevive = true
			heal_info.sender = user_party[i]
			heal_info.target = user_party[i]

			command_util.execute_heal(heal_info)
		end
	end

	eat_sfx:Stop()
	character_util.remove_anim(user_party_leader)
end

function local_class:set_item_sprites_on_shelf()
	for _, value in pairs(self.item_table) do
		local sprite = value.sprite

		for _, handle_name in ipairs(value.handle_names) do
			local gimmick = get_field_object(handle_name)

			if gimmick ~= nil then
				local spawn_pos = gimmick.Position + vector(0.1, 1.35, -0.3)
				local drop_item = self:generate_store_item_as_drop_item(value.id, 'dontfindlooter',
						spawn_pos)
				drop_item.ShadowTransform.gameObject:SetActive(false)

				self.items_on_shelf[#self.items_on_shelf + 1] = drop_item

				--self.items_in_shelf[#self.items_in_shelf + 1] = self:set_custom_sprite(spawn_pos, sprite)
			end
		end
	end
end

function local_class:exit_store(exit_marker_name)
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local pos_to_teleport = field:GetMarker(exit_marker_name).position


	character_util.move_to(user_party_leader,
			user_party_leader.Position + vector(0, 0, -0.8), 0.5,
			nil, true, true)

	coroutine.yield()

	music_player_util.play_sfx_one_shot('01_stage_in_teleport_01')
	screen_util.fade_out_circular_async(0.6, CS.Oak.Interpolations.EaseInOutSine)

	for i = 0, user_party.Count - 1 do
		character_util.set_position(user_party[i], pos_to_teleport + vector(i, 0, 0))
	end

	character_util.set_direction(user_party_leader, 'down')

	coroutine.yield()

	screen_util.fade_in_circular_async(0.6, CS.Oak.Interpolations.EaseInOutSine)

	party_util.reset_controllers()
	field_ui_manager:Show()

	self.is_leaving_store = false
end

-- 아이템 획득 연출 실행해주는 함수
function local_class:play_item_get(title, subtitle, desc)

	screen_util.item_get_event('demonworld_' .. title,
			self.string_key .. title, self.string_key .. subtitle, self.string_key ..desc)
end

function local_class:save_item_purchase_info(item_name, quantity)
	local saved_data = self.data_storage:get_data(item_name)
	saved_data = (saved_data == -1) and 0 or saved_data

	self.data_storage:set_data(item_name, saved_data + quantity)
end

--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
