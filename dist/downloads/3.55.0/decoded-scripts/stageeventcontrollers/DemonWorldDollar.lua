local local_class = newclass('DemonWorldDollarController')

function local_class:init()
	-- 리소스 홀더
	self.resholder = nil

	-- 보유 달러 양
	self.dollar_val = 0

	-- 게임 오버 시 달러 백업
	self.game_over_dollar = 0

	-- 이번 스테이지에서의 임시 달러량
	self.temporary_dollar_val = 0

	-- 소지금 UI
	self.dollar_ui = nil

	-- 소지금 UI Label
	self.dollar_ui_label = nil

	-- 달러 데이터 키
	self.dollar_data_key = 'dollar'

	-- 달러 아이템 ID
	self.dollar_item_id = 20339

	-- 메인 퀘스트 ID
	self.main_quest_id = 216

	-- 커스텀 이벤트
	self.dollar_add_event = 'dollar_add'
	self.dollar_remove_event = 'dollar_remove'
end

function local_class:load_resource()
	-- 메인 퀘스트 InnerProgress가 5, 6이면 작동하지 않음
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local main_quest_inner_progress = quest_progress.InnerProgress

	if main_quest_inner_progress >= 5 and main_quest_inner_progress <= 6 then
		return
	end

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_field_object_revived_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIShowEvent), 'on_field_ui_show_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIHideEvent), 'on_field_ui_hide_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')

	self.resholder = CS.Foundations.ResourceHolder()

	-- 소지금 UI 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/v2_15_demonworld/ui', 'dollar_ui', function(prefab)
				self.dollar_ui = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)

				self.dollar_ui_label = self.dollar_ui.transform:Find('Contents/Button/item/Amount/Label'):GetComponent(typeof(CS.UILabel))
				self.dollar_ui.transform:Find('Contents/Button/item/Amount/Dollar'):GetComponent(typeof(CS.UILabel)).text = game_string:GetString('demonworld_part1_dollar')
			end)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIShowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIHideEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
end

function local_class:on_stage_loaded_event(e)
	-- 저장소에서 달러, 현상 수배 레벨과 점수 로드하고 초기 설정
	local storage_create = require('utils/QuestDataStorage')
	self.data_storage = storage_create.create(221)

	self.dollar_val = self.data_storage:get_data(self.dollar_data_key)

	if self.dollar_val == -1 then
		self.dollar_val = 0
	end

	if self.dollar_ui_label ~= nil then
		self.dollar_ui_label.text = self.dollar_val
	end
end

function local_class:on_game_over_event(e)
	self.game_over_dollar = self.temporary_dollar_val
	self.temporary_dollar_val = 0
end

function local_class:on_field_object_revived_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		self.temporary_dollar_val = self.game_over_dollar
		self.game_over_dollar = 0
	end
end

function local_class:on_field_ui_show_event(e)
	if self.dollar_ui ~= nil then
		self.dollar_ui:SetActive(true)
	end
end

function local_class:on_field_ui_hide_event(e)
	if self.dollar_ui ~= nil then
		self.dollar_ui:SetActive(false)
	end
end

function local_class:add_dollar(amount, is_temporary, directing_data)
	local on_success = function()
		-- 달러 획득 이벤트 발송
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { self.dollar_add_event }))

		-- 달러 값 UI에 표시
		if self.dollar_ui_label ~= nil then
			self.dollar_ui_label.text = self.dollar_val + self.temporary_dollar_val
		end

		if directing_data ~= false then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.add_dollar_directing, self, amount, directing_data))
		end
	end

	if is_temporary == nil or not is_temporary then
		self.dollar_val = self.dollar_val + amount
		self.data_storage:set_data(self.dollar_data_key, self.dollar_val, on_success())
	else
		self.temporary_dollar_val = self.temporary_dollar_val + amount
		on_success()
	end
end

function local_class:add_dollar_async(amount, is_temporary, directing_data)
	local on_success = function()
		-- 달러 획득 이벤트 발송
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { self.dollar_add_event }))

		-- 달러 값 UI에 표시
		if self.dollar_ui_label ~= nil then
			self.dollar_ui_label.text = self.dollar_val + self.temporary_dollar_val
		end

		if directing_data ~= false then
			coroutine.yield(self:add_dollar_directing(amount, directing_data))
		end
	end

	if is_temporary == nil or not is_temporary then
		self.dollar_val = self.dollar_val + amount
		self.data_storage:set_data(self.dollar_data_key, self.dollar_val, on_success())
	else
		self.temporary_dollar_val = self.temporary_dollar_val + amount
		on_success()
	end
end

function local_class:add_dollar_directing(amount, directing_data)
	local dollar_item_id = 20339

	local pos = lua_helper.get_value(directing_data, 'pos')
	local target_pos = lua_helper.get_value(directing_data, 'target_pos',
			pos + vector(unity_class.random.Range(-0.5, 0.5), 0, unity_class.random.Range(-0.5, 0.5)))

	music_player_util.play_sfx_one_shot('01_dollars_01')

	local dollar_item = drop_item_util.create_item({ pos = pos, target = target_pos,
													 itemid = dollar_item_id, notforinven = true, sprscale = 0.5,
													 lootstate = 'dontfindlooter', skip_text = true })

	wait_for_sec(1)

	dollar_item.ConsumeTarget = user_party.Leader
	dollar_item:Fly()

	while ((user_party_leader.Position:GetX0z() -
			dollar_item.Position:GetX0z()).magnitude > 0.3) do
		coroutine.yield(nil)
	end

	CS.Oak.FieldUIFloatingText.Get(user_party.Leader):JustPrintItemName('+' .. (amount) .. ' ' ..
			game_string:GetString('demonworld_part1_dollar'), 0)
end

function local_class:remove_dollar(amount, is_temporary, directing_data)
	local on_success = function()
		-- 달러 소모 이벤트 발송
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { self.dollar_remove_event }))

		-- 달러 값 UI에 표시
		if self.dollar_ui_label ~= nil then
			self.dollar_ui_label.text = self.dollar_val + self.temporary_dollar_val
		end

		if directing_data ~= false then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.remove_dollar_directing, self, amount, directing_data))
		end
	end

	if is_temporary == nil or not is_temporary then
		self.dollar_val = self.dollar_val - amount
		self.data_storage:set_data(self.dollar_data_key, self.dollar_val, on_success())
	else
		self.temporary_dollar_val = self.temporary_dollar_val - amount

		on_success()
	end
end

function local_class:remove_dollar_async(amount, is_temporary, directing_data)
	local on_success = function()
		-- 달러 소모 이벤트 발송
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { self.dollar_remove_event }))

		-- 달러 값 UI에 표시
		if self.dollar_ui_label ~= nil then
			self.dollar_ui_label.text = self.dollar_val + self.temporary_dollar_val
		end

		if directing_data ~= false then
			coroutine.yield(self:remove_dollar_directing(amount, directing_data))
		end
	end

	if is_temporary == nil or not is_temporary then
		self.dollar_val = self.dollar_val - amount
		self.data_storage:set_data(self.dollar_data_key, self.dollar_val, on_success())
	else
		self.temporary_dollar_val = self.temporary_dollar_val - amount

		on_success()
	end
end

function local_class:remove_dollar_directing(amount, directing_data)
	local minus_string = '-'
	if amount == 0 then
		minus_string = ''
	end

	local play_sfx = lua_helper.get_value(directing_data, 'play_sfx', true)
	if play_sfx then
		music_player_util.play_sfx_one_shot('01_hit_comic_01')
	end

	CS.Oak.FieldUIFloatingText.Get(user_party.Leader):JustPrintItemName(minus_string .. (amount) .. ' ' ..
			game_string:GetString('demonworld_part1_dollar'), 0)
end

function local_class:get_dollar()
	return self.dollar_val + self.temporary_dollar_val
end

function local_class:on_stage_end_event(e)
	self.data_storage:set_data(self.dollar_data_key, self.dollar_val + self.temporary_dollar_val)
end

return {
	create = function()
		return local_class();
	end
}
