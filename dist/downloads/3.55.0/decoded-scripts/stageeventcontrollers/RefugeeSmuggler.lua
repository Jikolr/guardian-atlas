local local_class = newclass("RefugeeSmugglerController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 오브젝트 이름
	self.door_name = 'cave_door_1'

	-- 존 이름
	self.smuggler_zone_name = 'smuggler_zone'

	-- 아이템 스펙 이름
	self.book_item_spec_name = 'smuggler_book'

	-- 캐릭터들을 얻어오는 함수
	self.get_smuggler = function() return get_character('smuggler') end
	self.get_officer = function(num) return get_character('officer_' .. num) end

	-- 오브젝트들을 얻어오는 함수
	self.get_door = function() return get_field_object(self.door_name) end
	self.get_book = function() return get_field_object('smuggler_book') end

	-- 마커를 얻어오는 함수
	self.get_item_position_marker = function(num) return field:GetMarker('smuggler_item_position_' .. num).position end
	self.get_book_marker = function() return field:GetMarker('smuggler_book').position end

	-- sns follower id
	self.follower_id = 53

	-- sns follower 가 이미 추가되어 있는지
	self.is_added_sns_follower = false
	-- 밀수꾼이 혼자 궁시렁거리는 대사를 들었는지.
	self.is_saw_talk_alone = false
	-- 밀수꾼이 원하는 책을 가지고 있는지
	self.is_have_book = false
	-- 아이템을 여기저기 흩뿌리는 연출이 완료되었는지.
	self.is_drop_item_around_finish = false

	-- drop_item 변수
	self.book_drop_item = nil
	self.drop_item_around_list = nil

	-- 이벤트 자체 progress
	self.event_progress = {
		none = 0,
		request_find_book = 1
	}
	self.current_event_progress = self.event_progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')

	self.is_added_sns_follower = user_progress:IsFollowing(self.follower_id)

	-- sns follower 가 추가 되어 있지 않다면.
	if not self.is_added_sns_follower then
		local smuggler = self.get_smuggler()

		smuggler.Position = vector(133, 0, 99)
		smuggler.Interactable:AddListener(self.cs_controller)
		character_util.set_direction(smuggler, 'left')
		character_util.set_anim(smuggler, { name = 'eat' })

		local book = self.get_book()
		local book_marker = self.get_book_marker()

		book.Position = book_marker
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))

	local smuggler = self.get_smuggler()
	if lua_helper.type_compare(smuggler.Interactable, CS.Oak.NPCInteractable) then
		smuggler.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.book_drop_item = nil

	if self.drop_item_around_list ~= nil then
		for i = 1, #self.drop_item_around_list do
			self.drop_item_around_list[i]:ConsumeComplete()
			self.drop_item_around_list[i] = nil
		end
	end
	self.drop_item_around_list = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		return self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ItemGetEvent) then
		return self:on_item_get_event(e)
	end

	return false
end

function local_class:on_stage_start_event(e)
	-- sns follower 가 추가 되어 있지 않다면.
	if not self.is_added_sns_follower then
		local item_data = game_data_service.GetData('ItemData')
		local book_item_id = item_data:GetSpec(self.book_item_spec_name).Id
		local book_marker = self.get_book_marker()

		self.book_drop_item = drop_item_util.create_item({ pos = book_marker, itemid = book_item_id, notforinven = true, lootstate = 'dontfindlooter' })
	end

	return true
end

function local_class:on_interact_event(e)
	local smuggler = self.get_smuggler()
	local book = self.get_book()

	if lua_helper.reference_equals(e.Target, smuggler) then
		if self.current_event_progress == self.event_progress.none then
			sp_util.play_normal_screenplay(self.interact_smuggler, self)
			return true
		else
			sp_util.play_normal_screenplay(self.find_book, self)
			return true
		end
	elseif lua_helper.reference_equals(e.Target, book) then
		if self.current_event_progress == self.event_progress.request_find_book then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.get_book_item, self))
		else
			sp_util.play_normal_screenplay(self.interact_book, self)
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		if not self.is_saw_talk_alone and e.Zone.Name == self.smuggler_zone_name then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_alone, self))
			return true
		end
	end

	return false
end

function local_class:on_item_get_event(e)
	local item_data = CS.Oak.GameDataService.GetData("ItemData")

	if e.Getter == user_party_leader then
		if e.Item.ItemId == item_data:GetSpec(self.book_item_spec_name).Id then
			self.is_have_book = true
			return true
		end
	end

	return false
end

-- 밀수업자가 혼자 궁시렁 거림
function local_class:talk_alone()
	local smuggler = self.get_smuggler()

	self.is_saw_talk_alone = true

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.drop_item_around, self))

	-- 어디서 떨어뜨린 거야… 어렵게 구한 건데
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_1' })
end

-- 아이템을 4개정도 여기저기 흩뿌림.
function local_class:drop_item_around()
	local smuggler = self.get_smuggler()
	local item_data = game_data_service.GetData('ItemData')

	self.drop_item_around_list = {}
	-- 주변에 흩뿌릴 아이템 목록
	local drop_item_spec_name_list = {
		'ice_queen_ring_accessory_epic',
		'the_earth_necklace_accessory_epic',
		'apple',
		'perfect_banana',
	}
	-- 주변에 흩뿌릴 아이템의 크기 목록
	local drop_item_scale_list = {
		0.7,
		0.7,
		1,
		1
	}
	for i = 1, #drop_item_spec_name_list do
		local drop_item_id = item_data:GetSpec(drop_item_spec_name_list[i]).Id
		local item_position_marker = self.get_item_position_marker(i)
		local scale = drop_item_scale_list[i]
		local drop_item = drop_item_util.create_item({ pos = smuggler.Position, target = item_position_marker, itemid = drop_item_id, notforinven = true, lootstate = 'dontfindlooter', sprscale = scale })

		table.insert(self.drop_item_around_list, drop_item)
		wait_for_sec(1)
	end

	self.is_drop_item_around_finish = true
end

-- 책에 상호작용
function local_class:interact_book()
	field_ui_util.show_narration_async({ key = 'refugee_smuggler_16' })
end

-- 책을 얻는 연출
function local_class:get_book_item()
	local book = self.get_book()

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	field_ui_util.show_narration_async({ key = 'refugee_smuggler_16' })

	field_ui_manager:Show()

	character_util.set_side_direction(user_party_leader)
	character_util.set_anim(user_party_leader, { name = 'eat' })
	wait_for_sec(2)

	character_util.remove_anim(user_party_leader)

	self.book_drop_item.ConsumeTarget = user_party_leader
	self.book_drop_item = nil
	wait_for_sec(1)

	character_util.set_active_state(book, 'disabled')

	party_util.reset_controllers()
end

-- 밀수업자에게 상호작용
function local_class:interact_smuggler()
	local smuggler = self.get_smuggler()

	party_util.align_to_target(smuggler, 'right', 1, 'arc')

	while not self.is_drop_item_around_finish do
		coroutine.yield(nil)
	end

	-- 어… 어…!
	character_util.look_at(smuggler, user_party_leader)
	character_util.set_emotion(smuggler, { name = 'surprise' })
	character_util.set_anim(smuggler, { name = 'embarrassed' })
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_2', skip = true })

	-- 안녕하십니까, 부소장님!
	character_util.remove_emotion(smuggler)
	character_util.set_anim(smuggler, { name=  'salute', loop = false, sfx_name = '02_twohand_stomp_jump_01' })
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_3', skip = true })

	character_util.set_anim(user_party_leader, { name = 'nod' })
	wait_for_sec(0.9)

	-- 어… 저… 그… 구호품을 나르고 있었습니다!
	character_util.remove_anim(user_party_leader)
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_4', skip = true })

	-- 구호품 중 보석이 있던가? / 밀수품 아냐, 이거?
	choose_util.play_choose_event({ { 'refugee_smuggler_4_1', 'intellect' }, { 'refugee_smuggler_4_2', 'brutal' } })

	-- 아… 그… 어…
	character_util.set_emotion(smuggler, { name = 'scared' })
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_5', skip = true })

	character_util.set_emotion(snuggler, { name = 'tired' })
	character_util.set_direction(smuggler, 'left')
	character_util.set_anim(smuggler, { name = 'question', loop = false })

	-- emoticon_bubble_silence를 띄운 후
	character_util.show_emoticon_async(smuggler, nil, 'silence')

	-- 부소장님, 혹시 갖고 싶은 물건… 없으십니까? 제가 뭐든지 구해다드릴 수 있습니다.
	character_util.look_at(smuggler, user_party_leader)
	character_util.set_emotion(smuggler, { name = 'doyagao' })
	character_util.remove_anim(smuggler)
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_6', skip = true })

	character_util.set_anim(user_party_leader, { name = 'question', loop = false })
	wait_for_sec(0.5)

	-- 전설 각성석 / 아르마다 / 메이릴 / 수용소 사람들 모두에게 나누어줄 침구
	choose_util.play_choose_event({ { 'refugee_smuggler_6_1', 'brutal' }, { 'refugee_smuggler_6_2', 'forced' }, { 'refugee_smuggler_6_3', 'intellect' }, { 'refugee_smuggler_6_4', 'mercy' } })

	-- 문제 없습니다!
	character_util.remove_anim(user_party_leader)
	character_util.set_emotion(smuggler, { name = 'smile' })
	character_util.set_anim(smuggler, { name = 'victory_get', loop = false })
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_7', skip = true })

	-- 제가 지하통로 어딘가에서 떨어뜨린 책이 하나 있는데…
	character_util.set_anim(smuggler, { name = 'sing' })
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_8', skip = true })

	-- 그 책만 찾아주시면 2주 안에 구해드리죠!
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_9', skip = true })

	character_util.remove_anim(smuggler)

	self.current_event_progress = self.event_progress.request_find_book
end

-- 밀수업자에게 책을 찾아서 가져다 줬을 때
function local_class:find_book()
	local smuggler = self.get_smuggler()
	local officer_1 = self.get_officer(1)
	local officer_2 = self.get_officer(2)

	party_util.align_to_target(smuggler, 'right', 1, 'arc')

	if not self.is_have_book then
		-- 아직 책을 찾지 못했을 때.
		character_util.set_anim(smuggler, { name = 'release', sfx_name = '01_swing_01' })
		speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_9', skip = true })

		character_util.remove_anim(smuggler)

		return
	end

	yield_return_func(self.throw_item_to_smuggler, self, self.book_item_spec_name)

	-- 오오…! 찾았다!
	character_util.normal_jump(smuggler, true)
	character_util.set_emotion(smuggler, { name = 'surprise' })
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_10', skip = true })

	-- 그래서, 아까 필요하신 게 뭐라고…
	character_util.set_emotion(smuggler, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_11', skip = true })

	officer_1.Position = vector(134, 0, 104)
	officer_2.Position = vector(135, 0, 104)

	-- shout 말풍선 (저 더러운 밀수꾼 자식! 잡아라!)
	camera_util.shake(0.1, 1)
	speech_bubble_util.show_speech_bubble_async(officer_1, { key = 'refugee_smuggler_12', bubble_type = 'shout', skip = true, world_pos = vector(133, 0, 100) })

	-- 으아아…!
	character_util.set_emotion(smuggler, { name = 'scared' })
	character_util.set_anim(smuggler, { name = 'embarrassed' })
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_13', skip = true })

	-- 땅에 떨어진 물건들을 주움
	-- 4가지 아이템의 위치를 기반으로, 4각형(Rect) 형태의 이동 루트를 만듦.
	local left = self.drop_item_around_list[1].Position.x
	local right = self.drop_item_around_list[1].Position.x
	local top = self.drop_item_around_list[1].Position.z
	local bottom = self.drop_item_around_list[1].Position.z
	for i = 2, #self.drop_item_around_list do
		local drop_item = self.drop_item_around_list[i]

		if drop_item.Position.x < left then
			left = drop_item.Position.x
		end
		if drop_item.Position.x > right then
			right = drop_item.Position.x
		end
		if drop_item.Position.z > top then
			top = drop_item.Position.z
		end
		if drop_item.Position.z < bottom then
			bottom = drop_item.Position.z
		end
	end

	for i = 1, #self.drop_item_around_list do
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pick_up_drop_item, self, smuggler, self.drop_item_around_list[i]))
	end
	local around_position_list = {
		vector(right, 0, bottom),
		vector(right, 0, top),
		vector(left, 0, top),
		vector(left, 0, bottom),
		smuggler.Position
	}
	character_util.move_waypoint_async(smuggler, around_position_list, 7, true, nil, 'right')

	-- SNS 등록
	yield_return_func(CS.Oak.AddSNSCoroutine, self.follower_id)

	-- 연락처 받으셨죠?! 다음에 찾아드릴게요! 다음에!!!
	speech_bubble_util.show_speech_bubble_async(smuggler, { key = 'refugee_smuggler_14', skip = true })

	-- (아래 문 열려있든 말든) 스위치로 이동 후 아래->오른쪽으로 도망간다
	character_util.move_waypoint_async(smuggler, vector(134, 0, 99), 7, true, nil, nil, nil)

	-- 만약에 아래쪽에 문이 열려있지 않은 경우, 문을 열고서 내려감.
	local door = self.get_door()
	if not door.FieldObjectBehaviour.IsOpen then
		character_util.move_waypoint_async(smuggler, vector(134, 0, 97), 7, true, nil, nil, nil)
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name, false))
		wait_for_sec(2)
	end

	character_util.move_waypoint_async(smuggler, vector(134, 0, 94), 7, true, nil, nil, nil)
	character_util.remove_emotion(smuggler)
	character_util.set_active_state(smuggler, 'disabled')

	-- 그 뒤를 steampunk_officer 두 명이 (저 놈 잡아! 대사와 함께 따라감)
	speech_bubble_util.show_speech_bubble_async(officer_1, { key = 'refugee_smuggler_15', bubble_type = 'shout', skip = true, world_pos = vector(133, 0, 100) })
	character_util.move_waypoint(officer_1, vector(134, 0, 94), 7, true, nil, nil, nil)
	character_util.move_waypoint_async(officer_2, vector(135, 0, 94), 7, true, nil, nil, nil)
	character_util.set_active_state(officer_1, 'disabled')
	character_util.set_active_state(officer_2, 'disabled')

	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })
end

-- 밀수꾼에게 아이템을 던져줌.
function local_class:throw_item_to_smuggler(item_spec_name)
	local smuggler = self.get_smuggler()
	local item_data = game_data_service.GetData('ItemData')
	local item_id = item_data:GetSpec(item_spec_name).Id
	local item = drop_item_util.create_item({ pos = user_party_leader.Position, target = smuggler.Position, itemid = item_id, notforinven = true })

	music_player:PlaySfxOneShot("01_player_popup_01")
	item.ConsumeTarget = smuggler

	wait_for_sec(2)
end

-- 밀수꾼이 돌아다니면서 아이템을 주움
function local_class:pick_up_drop_item(fo, item)
	while true do
		local distance = (item.Position - fo.Position).magnitude

		if distance <= 0.5 then
			break
		end

		coroutine.yield(nil)
	end

	item.ConsumeTarget = fo
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
