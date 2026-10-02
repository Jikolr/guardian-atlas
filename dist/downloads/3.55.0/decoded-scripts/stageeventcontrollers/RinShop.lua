local local_class = newclass('RinShop')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 게임 종료
	self.end_game = false

	-- 기타 상수
	self.can_item_id = 20257
	self.can_block_num = 2

	-- 타일맵의 필드오브젝트 이름
	self.conveyor_belt_name_1 = '[gimmick]beltC'
	self.conveyor_belt_name_2 = '[gimmick]beltR'
	self.conveyor_belt_name_3 = '[gimmick]beltL'
	self.can_block_name = 'can_block_'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.MiniGameEndEvent), 'on_event')

	self.merchant = get_character('merchant')
	character_util.add_listener(self.merchant, self.cs_controller)
	self.hunter = get_character('hunter')
	character_util.add_listener(self.hunter, self.cs_controller)
	self.idol = get_character('idol')
	character_util.add_listener(self.idol, self.cs_controller)
	self.builder = get_character('builder')
	character_util.add_listener(self.builder, self.cs_controller)

	character_util.set_position(self.idol, vector(3, 0, 9))
	character_util.set_position(self.merchant, vector(0, 0, 9))
	character_util.set_position(self.hunter, vector(-1.5, 0, 9))
	character_util.set_position(self.builder, vector(1.5, 0, 9))
end

function local_class:dispose()
	self.end_game = true

	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MiniGameEndEvent))

	self.cs_controller = nil
end

function local_class:need_on_launch()
	local main_quest_id = 7000401
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	return main_quest ~= nil and not main_quest.IsComplete and
			(main_quest.InnerProgress == 0 or main_quest.InnerProgress == 4)
end

function local_class:on_launch(_)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_stage_start_event(e)
	self:activate_conveyor_belts()
	self:set_soylent_cans()

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_soylent_cans, self))
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.merchant) then
		message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { 'RinShop', 'merchant_interact_event' }))
		return true

	elseif lua_helper.reference_equals(e.Target, self.hunter) then
		message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { 'RinShop', 'hunter_interact_event' }))
		return true

	elseif lua_helper.reference_equals(e.Target, self.idol) then
		message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { 'RinShop', 'idol_interact_event' }))
		return true

	elseif lua_helper.reference_equals(e.Target, self.builder) then
		message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { 'RinShop', 'builder_interact_event' }))
		return true
	end
	return false
end

-- 컨베이어 벨트 작동
function local_class:activate_conveyor_belts()
	-- 타일맵 Gimmick 레이어 순회해서 컨베이어 벨트 전부 찾음
	local tilemap = field.Tilemap

	local gimmick_layer = tilemap.transform:Find('gimmick')

	for i = 0, gimmick_layer.transform.childCount - 1 do
		local cur_transform = gimmick_layer.transform:GetChild(i)

		if cur_transform.name == self.conveyor_belt_name_1 or cur_transform.name == self.conveyor_belt_name_2 or
				cur_transform.name == self.conveyor_belt_name_3 then
			local animator = cur_transform:GetComponent(typeof(CS.UnityEngine.Animator))
			animator:Play('xmas_belt_rolling')
			animator.speed = 3
		end
	end
end

-- 3번 방에 소일렌트 통조림 생성
function local_class:set_soylent_cans()
	local start_pos_list = { vector(157.5, 0, -69), vector(158.5, 0, -72) }

	for n = 1, 2 do
		local can_num = 9
		local index = 0
		local index_max = 5
		local index_sub = 2
		local count = 0
		local add_y = 0.7

		for i = 0, can_num - 1 do
			index = index + 1

			if index > index_max then
				index = 1

				index_max = index_max - index_sub

				count = count + 1
			end

			local cur_x = start_pos_list[n].x + 0.35 * (count + index)
			local cur_y = add_y * count
			local cur_z = start_pos_list[n].z

			local can = drop_item_util.create_item({ pos = vector(cur_x, cur_y, cur_z),
			                             itemid = self.can_item_id, notforinven = true, lootstate = 'dontfindlooter' })

			if count > 0 then
				can:SetSortingLayer(true)
			end
		end
	end

	-- 통조림 충돌 판정 처리할 오브젝트 Hitbox 크기 조절
	for i = 1, self.can_block_num do
		local cur_block = get_field_object(self.can_block_name..i)

		cur_block.Hitbox = CS.Oak.Hitbox(vector(1.8, 2, 1))
	end
end

-- 컨베이어 벨트를 따라 이동하는 통조림 처리
function local_class:move_soylent_cans()
	-- 각 컨베이어 벨트마다 통조림 이동 루틴 실행

	local timer = 0
	local can_delay = 1.5
	local can_num = 6

	local can_start_pos_list = { vector(131, 0.6, -68), vector(131, 0.6, -73),
	                             vector(148, 0.6, -66), vector(148, 0.6, -75),
	                             vector(162, 0.6, -74), vector(154, 0.6, -60) }

	local can_end_pos_list = { vector(122, 0.6, -68), vector(122, 0.6, -73),
	                           vector(138, 0.6, -66), vector(138, 0.6, -75),
	                           vector(162, 0.6, -67), vector(154, 0.6, -53)}

	local can_duration_list = { 4.5, 4.5, 5, 5, 3.5, 3.5 }

	while not self.end_game do
		timer = timer + unity_class.time.deltaTime

		if not self.end_game and timer >= can_delay then
			timer = 0

			for i = 1, can_num do
				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.control_soylent_can, self, can_start_pos_list[i], can_end_pos_list[i],
								can_duration_list[i]))
			end
		end

		coroutine.yield(nil)
	end
end

-- 각각의 캔이 생성되서 사라지기까지 처리
function local_class:control_soylent_can(start_pos, end_pos, duration)
	local fade_duration = 0.3

	-- 캔 생성
	local can = drop_item_util.create_item({ pos = start_pos,
	                                         itemid = self.can_item_id, notforinven = true, lootstate = 'dontfindlooter' })

	can.ShadowTransform.gameObject:SetActive(false)
	drop_item_util.alpha_fade_async(can, 0, 0)

	drop_item_util.alpha_fade_in_async(can, fade_duration)

	local cur_time = unity_class.time.time

	while unity_class.time.time - cur_time < duration do
		local cur_pos = unity_class.vector3.Lerp(start_pos, end_pos, (unity_class.time.time - cur_time) / duration)

		can:SetPosition(cur_pos)

		coroutine.yield(nil)
	end

	drop_item_util.alpha_fade_async(can, 0, fade_duration)

	drop_item_util.dispose_item(can)
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
