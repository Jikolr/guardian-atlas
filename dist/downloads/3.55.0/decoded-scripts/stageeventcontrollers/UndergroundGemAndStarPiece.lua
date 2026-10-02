local local_class = newclass('UndergroundGemAndStarPieceController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 기믹
	self.get_gem = function(index) return get_field_object(self.gem_name .. index) end
	self.get_star_piece = function(index) return get_field_object(self.star_piece_name .. index) end
	self.get_interact_gem = function(index) return get_field_object(self.gem_interact_name .. index) end
	self.get_interact_star_piece = function(index) return get_field_object(self.star_piece_interact_name .. index) end

	-- 이펙트
	self.get_effect = function() return unity_object_pool.GetOrCreate('fx_object_twinkle_single')  end

	-- 젬 아이템 아이디
	self.gem_item_id = 20294

	-- 메인 퀘스트 아이디
	self.main_quest_id = 208

	-- 실제 젬, 스타피스
	self.gem_name = 'underground_gem_'
	self.star_piece_name = 'underground_star_piece_'

	-- 상호작용 젬, 스타피스
	self.gem_interact_name = 'underground_gem_interact_'
	self.star_piece_interact_name = 'underground_star_piece_interact_'

	-- 메인 퀘스트에 저장할 커스틈 스테이트 키 이름
	self.custom_state_key = 'is_show_underground_event'

	-- 상호작용 젬, 스타피스
	self.gem_gimmicks = {}
	self.star_piece_gimmicks = {}

	-- 실제 젬과 스타피스
	self.gems = {}
	self.star_pieces = {}

	-- 이펙트들
	self.effects = {}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_item_get_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	quest_util.load_pool_resource(
		'fx_object_twinkle_single'
	)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))

	for k, effect in pairs(self.effects) do
		if effect then
			self.effects[k]:Dispose()
			self.effects[k] = nil
		end
	end

	self.gem_gimmicks = nil
	self.star_piece_gimmicks = nil
	self.gems = nil
	self.star_pieces = nil

	self.cs_controller = nil
end

--- OnEvent
function local_class:on_event(e)
	return false
end

--- StageLoadedEvent
function local_class:on_stage_loaded_event(e)
	-- 이벤트를 봤는지
	local main_progress = user_progress:GetStartedQuest(self.main_quest_id)
	self.is_show_event = quest_util.get_custom_state(main_progress, self.custom_state_key) ~= -1

	-- 젬 인터랙트 세팅
	local gem_index = 1
	while true do
		local gimmick = self.get_interact_gem(gem_index)

		if not gimmick then break end

		self.gem_gimmicks[gimmick] = gem_index
		gimmick.Interactable = CS.Oak.PublishInteractable.Create()
		gimmick.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		local gem = self.get_gem(gem_index)
		-- 아이템을 이미 획득했는지 체크
		if not gem.FieldObjectBehaviour.IsGetted then
			local effect = self.get_effect():Instantiate(gimmick.Position)
			self.effects[gimmick] = effect
			self.gems[gimmick] = gem
		else
			gimmick.Position = vector(999, 0, 999)
			gimmick.ActiveState = active_state('disabled')
		end

		gem_index = gem_index + 1
	end

	-- 스타피스 인터랙트 세팅
	local star_piece_index = 1
	while true do
		local gimmick = self.get_interact_star_piece(star_piece_index)

		if not gimmick then break end

		self.star_piece_gimmicks[gimmick] = star_piece_index
		gimmick.Interactable = CS.Oak.PublishInteractable.Create()
		gimmick.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		-- 스타피스를 이미 획득했는지 체크
		if not star_piece_util.has_star_piece(self.star_piece_name .. star_piece_index) then
			local effect = self.get_effect():Instantiate(gimmick.Position)
			self.effects[gimmick] = effect
			self.star_pieces[gimmick] = self.get_star_piece(star_piece_index)
		else
			gimmick.Position = vector(999, 0, 999)
			gimmick.ActiveState = active_state('disabled')
		end

		star_piece_index = star_piece_index + 1
	end

	return true
end

--- InteractEvent
function local_class:on_interact_event(e)
	for k, _ in pairs(self.gem_gimmicks) do
		if lua_helper.reference_equals(e.Target, k) then
			sp_util.play_normal_screenplay(self.interact_gimmick, self, k, true)
			return true
		end
	end

	for k, _ in pairs(self.star_piece_gimmicks) do
		if lua_helper.reference_equals(e.Target, k) then
			sp_util.play_normal_screenplay(self.interact_gimmick, self, k, false)
			return true
		end
	end

	return false
end

--- ItemGetEvent
function local_class:on_item_get_event(e)
	if e.Item.ItemId == self.gem_item_id then
		local gem = self.gems[e.Dropper]

		-- 획득한 젬 수량으로 텍스트 출력
		local text = CS.Oak.FieldUIFloatingText.Get(user_party.Leader)
		text:JustPrintItemName(game_string:Format('underground_gem', gem.FieldObjectBehaviour.Item.Amount))

		-- 실제 젬 획득 처리
		self:acquire_gem(gem)

		return true
	end

	return false
end

--- 인터랙트에 상호작용 했을 때 연출
function local_class:interact_gimmick(gimmick, gem)
	local leader = user_party.Leader

	if not self.is_show_event then
		character_util.set_emotion(leader, { name = 'surprise' })
		music_player_util.play_sfx_one_shot('01_gatcha_point_01')
		-- 반짝이는 거!
		speech_bubble_util.show_speech_bubble_async(leader,
			{ key = 'underground_gem_and_star_piece_1', skip = true })

		character_util.remove_emotion(leader)
	end

	character_util.set_side_direction(leader)

	local eat_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true })
	character_util.set_anim(leader, { name = 'eat' })
	wait_for_sec(1)

	eat_sfx:Stop()

	character_util.remove_anim(leader)

	self.effects[gimmick]:Dispose()
	self.effects[gimmick] = nil

	if gem then
		-- 젬 드랍
		music_player_util.play_sfx_one_shot('03_treasure_item_popup_01')
		local gem_item = drop_item_util.create_item(
			{ pos = gimmick.Position, target = gimmick.Position, itemid = self.gem_item_id,
			  notforinven = true, sprscale = 0.5, skip_text = true, dropper = gimmick })

		gem_item.ConsumeTarget = leader
	else
		-- 스타피스 드랍
		music_player_util.play_sfx_one_shot('03_gimmick_jingle_01')
		star_piece_util.appear(self.star_pieces[gimmick])
	end

	if not self.is_show_event then
		character_util.set_emotion(leader, { name = 'smile' })
		character_util.set_animation_n_times(leader, { name = 'taunt'})

		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		-- 찾았다! {0}이(가) 좋아하는 거!
		speech_bubble_util.show_speech_bubble_async(leader,
			{ key = game_string:Format('underground_gem_and_star_piece_2', user.Name), skip = true })

		character_util.remove_anim_and_emotion(leader)

		self.is_show_event = true
		local main_progress = user_progress:GetStartedQuest(self.main_quest_id)
		quest_util.set_custom_state(main_progress, self.custom_state_key, 1)
	end

	gimmick.Position = vector(999, 0, 999)
	gimmick.ActiveState = active_state('disabled')
end

--- 실제 젬 획득
function local_class:acquire_gem(gem)
	stage:SendPickStageItem(gem.Name, nil, function(data)
		local has_value, value = data:TryGetValue('AddedItem')
		local added_item = value

		if added_item ~= nil then
			CS.Oak.StageProgress.Current:AddItem(gem.KeyIndex)

			-- 네비게이션바 상자 카운트 갱신을 위한 처리
			message_system:Publish(CS.Oak.ItemGetEvent.Create(user_party_leader, gem.FieldObjectBehaviour.Item))

			has_value, value = added_item:TryGetValue('Id')
			local item_id = value

			has_value, value = user.Items:TryGetValue(item_id)
			if has_value then
				CS.Oak.AddItemStageLogic.Execute(value, user_party_leader)
			end
		end
	end)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
