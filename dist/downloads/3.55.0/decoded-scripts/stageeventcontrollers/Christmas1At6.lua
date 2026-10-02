local local_class = newclass("Christmas1At6Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 캐릭터를 가져오는 함수
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		end

		return get_character('knight_female')
	end

	-- 오브젝트를 가져오는 함수
	self.get_princess_gift_chest = function() return get_field_object('princess_gift_chest') end

	-- 스타피스를 가져오는 함수
	self.get_star_piece = function(num) return get_field_object('chest_star_piece_' .. num) end

	-- 퍼플코인을 가져오는 함수
	self.get_purple_coin = function(num) return get_field_object('purple_coin_' .. num) end

	-- 마커를 가져오는 함수
	self.get_paper_piece_marker = function() return field:GetMarker('paper_piece') end

	-- 맵 안에 있는 퍼플코인 갯수
	self.purple_coin_num = 25

	-- 맵 안에 있는 스타피스 개숫
	self.star_piece_num = 3
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.TreasureOpenedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')

	-- 상자를 이미 열었다면, 스타피스와 퍼플코인을 보이게 한다.
	local princess_gift_chest = self.get_princess_gift_chest()
	if princess_gift_chest.FieldObjectBehaviour.IsOpened then
		for i = 1, self.star_piece_num do
			local star_piece = self.get_star_piece(i)
			star_piece.FieldObjectBehaviour.IsHidden = false
		end

		-- private set인 IsHidden에 접근하기 위해
		xlua.private_accessible(typeof(CS.Oak.PurpleCoinBehaviour))

		for i = 1, self.purple_coin_num do
			local purple_coin = self.get_purple_coin(i)
			purple_coin.FieldObjectBehaviour.IsHidden = false
		end
	end
end

function local_class:need_on_launch()
	local christmas_main_quest_id = 60045
	local quest_progress = user_progress:GetStartedQuest(christmas_main_quest_id)
	local progress_list = {
		16,
		17
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
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.TreasureOpenedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		return self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.TreasureOpenedEvent) then
		return self:on_treasure_opened_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ItemGetEvent) then
		return self:on_item_get_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	self:change_manual_character()

	return true
end

function local_class:on_treasure_opened_event(e)
	local princess_gift_chest = self.get_princess_gift_chest()

	if lua_helper.reference_equals(e.Target, princess_gift_chest) then
		sp_util.play_normal_screenplay(self.open_princess_gift_chest, self)
		return true
	end

	return false
end

function local_class:on_item_get_event(e)
	if e.Getter == user_party.Leader then
		local item_data = game_data_service.GetData('ItemData')
		local gem_item_id = 20191

		if e.Item.ItemId == gem_item_id then
			CS.Oak.FieldUIFloatingText.Get(user_party.Leader):JustPrintItemName(game_string:GetString('christmas_main_princess_gem'), 0)
			return true
		end
	end

	return false
end
--endregion

-- 파티 리더를 크리스마스 전용 기사로 변경한다.
function local_class:change_manual_character()
	local knight = self.get_knight()
	local param = CS.Oak.CharacterConvertParam:ManualDefault()

	param.HidePreviousParty = true
	character_util.convert_to_manual_character(knight, param)
end

-- 공주가 놔둔 선물 상자를 열었을 때
function local_class:open_princess_gift_chest()
	local princess_gift_chest = self.get_princess_gift_chest()

	-- 상자가 열리는 연출 대기 시간
	wait_for_sec(1.25)

	for i = 1, self.star_piece_num do
		local star_piece = self.get_star_piece(i)
		star_piece_util.appear(star_piece, princess_gift_chest.Position + vector(-0.5, 0, -1))
	end

	-- 스타피스가 등장하는 연출 대기 시간
	wait_for_sec(1.7)

	for i = 1, self.purple_coin_num do
		local purple_coin = self.get_purple_coin(i)
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.purple_coin_appear_from_chest, self, purple_coin, princess_gift_chest, vector(-0.5, 0, -1), 0.75))
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		local items = {}
		-- 가짜 젬
		for i = 1, 12 do
			local x = random_util.get_random_int(-24, 24) * 0.1
			local y = random_util.get_random_int(-8, 8) * 0.1
			local get_random_pos = vector(x,0,y)
			get_random_pos.y = 0
			local cur_item = drop_item_util.create_item({ itemid = 20191, notforinven = true,
														  pos = princess_gift_chest.Bounds.center, target = user_party.Leader.Position + vector(0, 0, -1) + get_random_pos,
														  lootstate = 'dontfindlooter', sprscale = 0.9, skip_text = true })
			table.insert(items, cur_item)
			music_player:PlaySfxOneShot('03_treasure_item_popup_01')
			wait_for_sec(0.1)
		end

		wait_for_sec(1)
		for _, item in ipairs(items) do
			item.ConsumeTarget = user_party.Leader
		end
	end))
	wait_for_sec(0.75)

	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	character_util.set_direction(user_party.Leader, 'right')
	character_util.set_emotion(user_party.Leader, { name = 'surprise' })
	character_util.remove_anim(user_party.Leader)
	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(user_party.Leader, 'left')
	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(user_party.Leader, 'right')
	wait_for_sec(1)

	character_util.remove_emotion(user_party.Leader)
end

-- 퍼플코인이 상자에서 등장해, 원래 위치로 날아가는 연출
function local_class:purple_coin_appear_from_chest(purple_coin, chest, offset, duration)
	local end_position = purple_coin.Position
	local start_position = chest.Position + offset
	local time_passed = 0

	message_system:Send(purple_coin, CS.Oak.PurpleCoinAppearEvent.Instance)

	while time_passed < duration do
		local progress = (time_passed / duration)
		local position = unity_class.vector3.Lerp(start_position, end_position, progress)
		local y = unity_class.mathf.Sin(unity_class.mathf.PI * progress)

		purple_coin.Position = position + vector(0, 0, y)

		time_passed = time_passed + unity_class.time.deltaTime

		coroutine.yield()
	end

	purple_coin.Position = end_position
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
