local local_class = newclass("NightmareTeatans1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.ifo_util = CS.Oak.IFieldObjectExtensions

	self.playing_market_event = false
	self.is_interacting = false

	self.custom_state = {
		-- 꽃을 가진 개수
		get_flower_count = 0,
		-- 해당 무덤에 헌화 했는지
		is_donated_flower = 1,
		-- 마티 무덤 앞 꽃을 정리 했는지
		is_cleared_marty_flower = 2
	}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	self.juice_store = get_field_object('juice_store')
	self.ice_store = get_field_object('icecream_store')

	for i = 0, 8 do
		get_field_object('grave_' .. i).Interactable = CS.Oak.PublishInteractable.Create()
	end

	unity_object_pool.GetOrCreate('FX_starpiece_in_character')
	unity_object_pool.GetOrCreate('FX_get')
	CS.Oak.FieldUIFloatingText.PreLoad()
end

function local_class:need_on_launch()
	-- 악몽 티탄왕국 메인 퀘스트가 PreSection, Section1 일때 커스텀 인트로 진행
	local main_quest = user_progress:GetStartedQuest(81)
	return main_quest == nil or main_quest.InnerProgress == 0
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	if self.star_piece_effect ~= nil then
		self.star_piece_effect:Dispose()
	end

	self.star_piece_effect = nil

	self.juice_store = nil
	self.ice_store = nil
	self.cs_controller = nil
	self.ifo_util = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if e.Zone.Name == 'market_event' and not self.playing_market_event then
				self.playing_market_event = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.love_teatans_event, self))
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.teatan_trio_play_event, self))
			end
		end
	end

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		local father = get_character('teatan_father')
		character_util.set_anim(father, {name = 'release', scale = 0.5})

		self:custom_setting()
	end

	if event_type == typeof(CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, self.ice_store) then
			speech_bubble_util.show_speech_bubble(self.ice_store, {key = 'nightmare_teatans_ice_oneline', skip = true})
		elseif lua_helper.reference_equals(e.Target, self.juice_store) then
			speech_bubble_util.show_speech_bubble(self.juice_store, {key = 'nightmare_teatans_juice_oneline', skip = true})
		end

		if self.is_interacting then return false end

		for i = 0, 7 do
			if lua_helper.reference_equals(e.Target, get_field_object('grave_' .. i)) then
				self.is_interacting = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.interact_grave, self, i))
				return true
			end
		end

		-- grave_8은 마티 무덤
		if lua_helper.reference_equals(e.Target, get_field_object('grave_8')) then
			self.is_interacting = true
			if not self.is_cleared_marty_flower then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.interact_marty_grave, self))
				return true
			else
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.interact_grave, self, 8))
				return true
			end
		end

		for i = 0, 2 do
			if lua_helper.reference_equals(e.Target, get_field_object('flower_stand_' .. i)) then
				self.is_interacting = true
				if not self.sold_out then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.sell_flower_teatan, self, i))
				else
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.sold_out_flower, self, i))
				end
				return true
			end
		end
	end

	return false
end

function local_class:love_teatans_event()

	-- 바로 시작하면 플레이어가 못볼수도있으니까 1초 정도 대기
	coroutine.yield(coroutine_class.wait_for_sec(1))

	local holdup_teatan = get_character('power_robot_female')
	local love_teatan_1 = get_character('love_teatan_1')
	local love_teatan_2 = get_character('love_teatan_2')
	local holded = get_field_object('holded_prop')

	-- 들어올리는 sfx 재생
	music_player_util.play_sfx({
		sfx_name = '01_holdup_01', parent = holdup_teatan
	})

	holdup_teatan:SetAnimation('hold', false)
	character_util.move_to_async(holded, holdup_teatan.Position + unity_class.vector3.up * 1.7, 0.167)
	holdup_teatan:SetAnimation('hold_loop', true)

	love_teatan_1.Direction = character_util.get_direction('left')
	love_teatan_1:SetEmotion('surprise', true)
	love_teatan_1:Jump(0.5, 0.3)

	coroutine.yield(coroutine_class.wait_for_sec(1))

	holdup_teatan:SetEmotion('mad', true)
	holdup_teatan.Interactable.Talk = 'nightmare_teatans_love_teatan_1'

	love_teatan_1.Direction = character_util.get_direction('left')
	love_teatan_1:SetEmotion('love', true)
	love_teatan_1:SetAnimation('sing', true)
	love_teatan_1.Interactable.Talk = 'nightmare_teatans_love_teatan_2'
end

function local_class:teatan_trio_play_event()
	local trio_1 = get_character('play_kid_1')
	local trio_2 = get_character('play_kid_2')
	local trio_3 = get_character('play_kid_3')

	while(true) do
		trio_1:SetAnimation('spear_shield_attack', true)
		speech_bubble_util.show_speech_bubble_async(trio_1, {key = 'nightmare_teatans_kid_trio_1'})

		trio_2:SetAnimation('jingak', true)
		speech_bubble_util.show_speech_bubble_async(trio_2, {key = 'nightmare_teatans_kid_trio_2'})

		trio_3:SetAnimation('bow_attack', true)
		speech_bubble_util.show_speech_bubble_async(trio_3, {key = 'nightmare_teatans_kid_trio_3'})

		trio_1:RemoveAnimation()
		trio_1:Jump(0.5, 0.3)
		speech_bubble_util.show_speech_bubble_async(trio_1, {key = 'nightmare_teatans_kid_trio_4'})

		trio_2:RemoveAnimation()
		trio_3:RemoveAnimation()

		coroutine.yield(coroutine_class.wait_for_sec(3))
	end
end

-- 꽃 파는 상인과 대화
function local_class:sell_flower_teatan(index)
	local flower_stand = get_field_object('flower_stand_' .. index)
	flower_stand.Interactable = CS.Oak.NonInteractable.Instance

	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local flower_merchant = get_character('flower_merchant')
	local pos = flower_stand.Position + unity_class.vector3.back
	user_party:PositionParty(pos, CS.Oak.Direction.Up, 0.5, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	pos = flower_stand.Position + unity_class.vector3.forward
	coroutine.yield(self.ifo_util.MoveTo(flower_merchant, pos, nil, 2, true, true))

	character_util.set_direction(flower_merchant, 'down')

	speech_bubble_util.show_speech_bubble_async(flower_merchant,
		{ key = 'nightmare_teatans_1_flower_donation_1', skip = true })

	-- 꽃 구매 선택지
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true
	local buy = false

	branches:Add({
		Text = game_string:GetString('nightmare_teatans_1_flower_donation_2'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
			buy = true
		end})

	branches:Add({
		Text = game_string:GetString('nightmare_teatans_1_flower_donation_3'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(flower_merchant, branches)

	while wait do
		coroutine.yield(nil)
	end

	-- 선택지: 구매하기
	if buy then
		-- 내 소지금이 1000원이 되는지 체크
		if CS.Oak.User.Me.Gold >= 1000 then
			local stage_custom = stage_progress:SetCustomData(0, self.get_flower_count + 1)
			coroutine.yield(CS.Oak.StageApiRouter.SendPayGold(stage.StageId, 1000, stage_custom))

			music_player:PlaySfxOneShot('03_drop_gold_01')

			-- 가진 꽃 개수 추가
			self.get_flower_count = self.get_flower_count + 1

			-- 판 꽃 개수 추가
			self.sold_flower_count = self.sold_flower_count + 1

			speech_bubble_util.show_speech_bubble_async(flower_merchant,
				{ key = 'nightmare_teatans_1_flower_donation_7', skip = true })

			coroutine.yield(self:buy_flower(index))

			speech_bubble_util.show_speech_bubble_async(flower_merchant,
				{ key = 'nightmare_teatans_1_flower_donation_8', skip = true })
		else
			speech_bubble_util.show_speech_bubble_async(flower_merchant,
				{ key = 'nightmare_teatans_1_flower_donation_4', skip = true })
		end
	-- 선택지: 무시하기
	else
		flower_stand.Interactable = CS.Oak.PublishInteractable.Create()
	end

	self.is_interacting = false

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 꽃 구매 연출
function local_class:buy_flower(index)
	local flower_merchant = get_character('flower_merchant')
	character_util.set_anim(flower_merchant, { name = 'push' })
	local before_pos = flower_merchant.Position
	local pos = flower_merchant.Position + 0.5 * unity_class.vector3.back

	coroutine.yield(self.ifo_util.MoveTo(flower_merchant, pos, nil, 2, false, false))

	music_player:PlaySfxOneShot('01_holdup_01')

	-- 꽃을 듦
	character_util.set_anim(flower_merchant, { name = 'hold' })
	local selling_flower = get_field_object('selling_flower_' .. index)
	local hold_up_pos = flower_merchant.Position + vector(0, 0.7, 0.7)
	character_util.move_to_async(selling_flower, hold_up_pos, 0.15) -- hold 애니메이션 시간만큼 움직여준다.

	character_util.set_anim(flower_merchant, { name = 'hold_loop' })
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 꽃을 던짐
	character_util.remove_anim(flower_merchant)
	character_util.set_anim(flower_merchant, { name = 'throw' })

	local time_passed = 0
	local throw_time = 0.3
	local start_pos = selling_flower.Position
	local end_pos = user_party_leader.Position + 0.7 * unity_class.vector3.forward

	while time_passed < throw_time do
		time_passed = time_passed + unity_class.time.deltaTime
		local progress = unity_class.mathf.Clamp01(time_passed / throw_time)
		local height = unity_class.mathf.Sin(unity_class.mathf.PI / 2 * (1 + progress))
		local cur_xz = unity_class.vector3.Lerp(start_pos, end_pos, progress)

		selling_flower.Position = cur_xz:GetX0z(height * 0.5)

		coroutine.yield(nil)
	end

	character_util.remove_anim(flower_merchant)

	coroutine.yield(coroutine_class.wait_for_sec(0.1))

	music_player:PlaySfxOneShot('03_get_drop_item_01')

	-- 꽃 획득
	local text = CS.Oak.FieldUIFloatingText.Get(user_party_leader)
	text:JustPrintItemName(game_string:GetString('flower'))
	-- 아이템 획득 이펙트 생성
	local fx_get_pool = unity_object_pool.GetOrCreate('FX_get')
	fx_get_pool:Instantiate(selling_flower.Position)
	selling_flower.Position = vector(999, 0, 999)

	coroutine.yield(self.ifo_util.MoveTo(flower_merchant, before_pos, nil, 2, false, true))

	-- 꽃을 다 팔았는지 체크
	for i = 0, 2 do
		local flower_stand = get_field_object('flower_stand_' .. i)
		if lua_helper.type_compare(flower_stand.Interactable, CS.Oak.PublishInteractable) then
			return
		end
	end

	-- 꽃 9개 샀으면 리필 안 함
	if self.sold_flower_count > 8 then
		for i = 0, 2 do
			local flower_stand = get_field_object('flower_stand_' .. i)
			flower_stand.Interactable = CS.Oak.PublishInteractable.Create()
		end
		self.sold_out = true
		return
	end

	-- 다 팔았으면 리필
	local fill_count
	if self.sold_flower_count < 7 then
		fill_count = 3
	else
		fill_count = 3 - (self.sold_flower_count % 3)
	end
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fill_flower, self, fill_count - 1))
end

-- 꽃 다시 채움
function local_class:fill_flower(index)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	local flower_merchant = get_character('flower_merchant')

	for i = 0, index do
		local selling_flower = get_field_object('selling_flower_' .. i)
		local flower_stand = get_field_object('flower_stand_' .. i)

		local pos = flower_stand.Position + unity_class.vector3.forward
		coroutine.yield(self.ifo_util.MoveTo(flower_merchant, pos, nil, 3, true, true))

		character_util.set_direction(flower_merchant, 'down')
		coroutine.yield(coroutine_class.wait_for_sec(0.2))

		selling_flower.Position = flower_stand.Position + vector(0, 0.3, 0.5)
		coroutine.yield(coroutine_class.wait_for_sec(0.3))
	end

	for i = 0, index do
		local flower_stand = get_field_object('flower_stand_' .. i)
		flower_stand.Interactable = CS.Oak.PublishInteractable.Create()
	end
end

-- 꽃이 다 팔렸을 때 연출
function local_class:sold_out_flower(index)
	local flower_stand = get_field_object('flower_stand_' .. index)
	flower_stand.Interactable = CS.Oak.NonInteractable.Instance

	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local flower_merchant = get_character('flower_merchant')
	local pos = flower_stand.Position + unity_class.vector3.back
	user_party:PositionParty(pos, CS.Oak.Direction.Up, 0.5, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	pos = flower_stand.Position + unity_class.vector3.forward
	coroutine.yield(self.ifo_util.MoveTo(flower_merchant, pos, nil, 2, true, true))

	character_util.set_direction(flower_merchant, 'down')

	speech_bubble_util.show_speech_bubble_async(flower_merchant,
		{ key = 'nightmare_teatans_1_flower_sold_out', skip = true })

	flower_stand.Interactable = CS.Oak.PublishInteractable.Create()

	self.is_interacting = false

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 마티 무덤 상호작용
function local_class:interact_marty_grave()
	local grave = get_field_object('grave_8')
	grave.Interactable = CS.Oak.NonInteractable.Instance

	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local pos = grave.Position + unity_class.vector3.back
	user_party:PositionParty(pos, CS.Oak.Direction.Up, 1, CS.Oak.Party.AlignType.Arc)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	stage.FieldUINarrationBox:Show()
	coroutine.yield(stage.FieldUINarrationBox:SetNarration(
		game_string:GetString("nightmare_teatans_1_flower_donation_11"), 0, 1))
	stage.FieldUINarrationBox:Hide()
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true
	local clear = false

	branches:Add({
		Text = game_string:GetString('nightmare_teatans_1_flower_donation_9'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			clear = true
			wait = false
		end})

	branches:Add({
		Text = game_string:GetString('nightmare_teatans_1_flower_donation_10'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(grave, branches)

	while wait do
		coroutine.yield(nil)
	end

	if clear then
		character_util.set_anim(user_party_leader, { name = 'attack', loop = false, sfx_name = '01_rustle_01' })
		coroutine.yield(coroutine_class.wait_for_sec(0.2))

		get_field_object('marty_flower').Position = vector(999, 0, 999)
		coroutine.yield(coroutine_class.wait_for_sec(0.3))

		character_util.remove_anim(user_party_leader)

		self.is_cleared_marty_flower = true
		local stage_custom = stage_progress:SetCustomData(2, self.is_cleared_marty_flower)
		coroutine.yield(CS.Oak.NetworkManager.ApiConnection:SendSetCustom(stage.StageId, stage_custom))
	end

	grave.Interactable = CS.Oak.PublishInteractable.Create()

	self.is_interacting = false

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 무덤 상호작용
function local_class:interact_grave(index)
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local save_index = self.is_donated_flower
	for i = 0, index - 1 do
		save_index = math.floor(save_index / 10)
	end

	if self.get_flower_count < 1 or save_index % 10 == 1 then
		stage.FieldUINarrationBox:Show()
		local string_key = 'nightmare_teatans_1_tomb_' .. index
		coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString(string_key), 0, 1))
		stage.FieldUINarrationBox:Hide()
		coroutine.yield(coroutine_class.wait_for_sec(0.5))

		self.is_interacting = false

		field_ui_manager:Show()
		user_party:ResetControllers()
		return
	end

	local grave = get_field_object('grave_' .. index)

	local pos = grave.Position + 1.5 * unity_class.vector3.back
	user_party:PositionParty(pos, CS.Oak.Direction.Up, 1, CS.Oak.Party.AlignType.Arc)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true
	local donate = false

	branches:Add({
		Text = game_string:GetString('nightmare_teatans_1_flower_donation_5'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			donate = true
			wait = false
		end})

	branches:Add({
		Text = game_string:GetString('nightmare_teatans_1_flower_donation_6'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(grave, branches)

	while wait do
		coroutine.yield(nil)
	end

	if donate then
		coroutine.yield(self:donate_flower(index))
	end

	self.is_interacting = false

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 헌화하는 연출
function local_class:donate_flower(index)
	-- 헌화한 장소 저장
	local pos_index = 1
	for i = 0, index - 1 do
		pos_index = pos_index * 10
	end

	self.is_donated_flower = self.is_donated_flower + pos_index

	local stage_custom = stage_progress:SetCustomData(1, self.is_donated_flower)
	coroutine.yield(CS.Oak.NetworkManager.ApiConnection:SendSetCustom(stage.StageId, stage_custom))

	-- 가진 꽃 개수 감소
	self.get_flower_count = self.get_flower_count - 1
	stage_custom = stage_progress:SetCustomData(0, self.get_flower_count)
	coroutine.yield(CS.Oak.NetworkManager.ApiConnection:SendSetCustom(stage.StageId, stage_custom))

	coroutine.yield(coroutine_class.wait_for_sec(0.4))

	local donation_flower = get_field_object('donation_flower_' .. index)
	donation_flower.Position = user_party_leader.Position + unity_class.vector3.forward

	coroutine.yield(coroutine_class.wait_for_sec(0.4))

	music_player:PlaySfxOneShot('01_rustle_01')

	character_util.set_anim(user_party_leader, { name = 'push' })

	local grave = get_field_object('grave_' .. index)
	local pos = grave.Position + unity_class.vector3.back
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		self.ifo_util.MoveTo(user_party_leader, pos, 0.5, nil, true, false))

	local time_passed = 0
	local duration = 0.5

	local start_pos = donation_flower.Position
	local end_pos = grave.Position

	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime
		local progress = unity_class.mathf.Clamp01(time_passed / duration)

		donation_flower.Position = unity_class.vector3.Lerp(start_pos, end_pos, progress)

		coroutine.yield(nil)
	end

	character_util.remove_anim(user_party_leader)

	-- 스타피스 있는 묘지에 헌화하면
	if index == 6 then
		local star_piece = get_field_object('donation_star_piece')
		star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(grave.Position))
		self.star_piece_effect:Dispose()
	end
end

-- 커스텀 및 이벤트 세팅
function local_class:custom_setting()
	-- 6번 무덤에 헌화를 했으면 스타피스 나타나 있도록 하기 위한 플래그
	self.appear_donation_star_piece = false
	-- 꽃을 가진 개수
	self.get_flower_count = stage_progress:GetCustomDataInt(self.custom_state.get_flower_count, 0)
	-- 헌화를 했는지 여부
	self.is_donated_flower = stage_progress:GetCustomDataInt(self.custom_state.is_donated_flower, 000000000)
	local save_index = self.is_donated_flower
	-- 팔린 꽃 개수
	self.sold_flower_count = self.get_flower_count
	for i = 0, 8 do
		if save_index % 10 == 1 then
			-- 6번 무덤에 헌화했으면 스타피스 나와있도록
			if i == 6 then
				self.appear_donation_star_piece = true
				local star_piece = get_field_object('donation_star_piece')
				star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(star_piece.Position))
			end

			self.sold_flower_count = self.sold_flower_count + 1

			-- true(1)면 무덤에 꽃 배치
			local grave = get_field_object('grave_' .. i)
			local flower = get_field_object('donation_flower_' .. i)
			flower.Position = grave.Position
		end

		save_index = math.floor(save_index / 10)
	end

	-- 꽃을 산 개수에 따라 다른 연출
	if self.sold_flower_count > 6 then
		for i = 0, self.sold_flower_count - 7 do
			local selling_flower = get_field_object('selling_flower_' .. i)
			local flower_stand = get_field_object('flower_stand_' .. i)
			flower_stand.Interactable = CS.Oak.NonInteractable.Instance
			selling_flower.Position = vector(999, 0, 999)
		end
		-- 꽃 다 팔았으면 다 팔았다는 상호작용 할 수 있도록
		if self.sold_flower_count > 8 then
			self.sold_out = true
			for i = 0, 2 do
				local flower_stand = get_field_object('flower_stand_' .. i)
				flower_stand.Interactable = CS.Oak.PublishInteractable.Create()
			end
		end
	else
		self.sold_out = false
	end

	self.is_cleared_marty_flower = stage_progress:GetCustomData(self.custom_state.is_cleared_marty_flower, false)
	if self.is_cleared_marty_flower then
		local flower = get_field_object('marty_flower')
		flower.Position = vector(999, 0, 999)
	end

	-- 스타피스 획득했거나 6번 무덤에 헌화했으면 이펙트 안 나오도록
	self.earned_donation_star_piece = stage_progress:HasStarPiece('donation_star_piece')
	if not self.earned_donation_star_piece and not self.appear_donation_star_piece then
		local pos = get_field_object('grave_6').Position + 0.5 * unity_class.vector3.down
		local fx_star_piece_pool = unity_object_pool.GetOrCreate('FX_starpiece_in_character')
		self.star_piece_effect = fx_star_piece_pool:Instantiate(pos)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
