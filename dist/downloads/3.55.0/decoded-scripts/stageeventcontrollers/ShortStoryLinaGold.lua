local local_class = newclass('ShortStoryLinaGoldController')

function local_class:init()

	self.quest_progress = nil

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
	self.dollar_data_key = 'gold_collect'

	-- 달러 아이템 ID
	self.dollar_item_id = 20001

	-- 메인 퀘스트 ID
	self.main_quest_id = 7000809

	-- 커스텀 이벤트
	self.dollar_add_event = 'lina_gold_add'
	self.dollar_remove_event = 'lina_gold_remove'

	self.wearing_clothes_data_key = 'wearing_clothes'
end

function local_class:load_resource()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	message_system:Subscribe(self, typeof(CS.Oak.FieldUIShowEvent), 'on_field_ui_show_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIHideEvent), 'on_field_ui_hide_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')

	self.resholder = CS.Foundations.ResourceHolder()

	-- 소지금 UI 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/castletown/ui', 'gold_ui', function(prefab)
				self.dollar_ui = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)

				self.dollar_ui_label = self.dollar_ui.transform:Find('Contents/Button/item/Amount/Label'):GetComponent(typeof(CS.UILabel))
				self.dollar_ui.transform:Find('Contents/Button/item/Amount/Dollar'):GetComponent(typeof(CS.UILabel)).text = game_string:GetString('short_story_sl_main_gold')
			end)
end

function local_class:on_stage_loaded_event(e)
	if self.data_storage == nil then
		self:load_data_storage()
	end
end

function local_class:load_data_storage()
	-- 저장소에서 달러, 현상 수배 레벨과 점수 로드하고 초기 설정
	local storage_create = require('utils/QuestDataStorage')
	self.data_storage = storage_create.create(self.main_quest_id)

	self.dollar_val = self.data_storage:get_data(self.dollar_data_key)

	if self.dollar_val == -1 then
		self.dollar_val = 0
	end

	if self.dollar_ui_label ~= nil then
		self.dollar_ui_label.text = self.dollar_val
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIShowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIHideEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
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

function local_class:get_quest_progress()
	if self.quest_progress == nil then
		self:refresh_quest_progress_cache()
	end
	return self.quest_progress
end

function local_class:refresh_quest_progress_cache()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
end

function local_class:apply_temporary_dollar()
	self.data_storage:set_data(self.dollar_data_key, self.dollar_val + self.temporary_dollar_val)
	self.dollar_val = self.dollar_val + self.temporary_dollar_val
	self.temporary_dollar_val = 0
end


function local_class:apply_temporary_dollar_async()
	self.data_storage:set_data_async(self.dollar_data_key, self.dollar_val + self.temporary_dollar_val)
	self.dollar_val = self.dollar_val + self.temporary_dollar_val
	self.temporary_dollar_val = 0
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
		-- BUG : 이거 실제로 저장 끝난 시점이 아니라 바로 호출되는 것 같은데 확인 필요함
		self.data_storage:set_data(self.dollar_data_key, self.dollar_val, on_success())
	else
		self.temporary_dollar_val = self.temporary_dollar_val + amount
		on_success()
	end
end

---@param additional_data table { {key: string, value: int} ... }
--- 특정 데이터를 같이 세팅하고자 하면 additional_data에 추가함. (ex : 특정 물품을 돈을 주고 구매하는 등)
function local_class:add_dollar_async(amount, is_temporary, directing_data, additional_data)
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

		-- 추가 데이터 저장이 필요 없으면 (돈만 저장하면 되는 경우)
		if additional_data == nil then
			self.data_storage:set_data_async(self.dollar_data_key, self.dollar_val, on_success)
		else
			-- 같이 저장할 데이터에 스테이지 전용 재화도 추가
			table.insert(additional_data, { key = self.dollar_data_key, value = self.dollar_val })
			self.data_storage:set_data_array(additional_data, on_success)
		end
	else
		self.temporary_dollar_val = self.temporary_dollar_val + amount
		on_success()
	end
end

function local_class:add_dollar_directing(amount, directing_data)
	local dollar_item_id = self.dollar_item_id

	local pos = lua_helper.get_value(directing_data, 'pos')
	local target_pos = lua_helper.get_value(directing_data, 'target_pos',
			pos + vector(unity_class.random.Range(-0.5, 0.5), 0, unity_class.random.Range(-0.5, 0.5)))

	music_player_util.play_sfx_one_shot('03_drop_gold_01')

	local dollar_item = drop_item_util.create_item({ pos = pos, target = target_pos,
													 itemid = dollar_item_id, notforinven = true, sprscale = 1,
													 lootstate = 'dontfindlooter', skip_text = true })

	wait_for_sec(1)

	dollar_item.ConsumeTarget = user_party.Leader
	dollar_item:Fly()

	while ((user_party.Leader.Position:GetX0z() -
		dollar_item.Position:GetX0z()).magnitude > 0.3) do
		coroutine.yield(nil)
	end

	music_player_util.play_sfx_one_shot('03_get_drop_gold_01')
	CS.Oak.FieldUIFloatingText.Get(user_party.Leader):JustPrintItemName('+' .. (amount) .. ' ' ..
			game_string:GetString('short_story_sl_main_gold'), 0)
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

---@param additional_data table { {key: string, value: int} ... }
function local_class:remove_dollar_async(amount, is_temporary, directing_data, additional_data)
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

		-- 추가 데이터 저장이 필요 없으면 (돈만 저장하면 되는 경우)
		if additional_data == nil then
			self.data_storage:set_data_async(self.dollar_data_key, self.dollar_val, on_success)
		else
			-- 같이 저장할 데이터에 스테이지 전용 재화도 추가
			table.insert(additional_data, { key = self.dollar_data_key, value = self.dollar_val })
			self.data_storage:set_data_array(additional_data, on_success)
		end
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
			game_string:GetString('short_story_sl_main_gold'), 0)
end

---@param diff number 잃거나 얻는 양 (잃는 경우 마이너스)
---@return number 바뀌고 난 후의 값을 반환
---이 함수에선 커스텀 스테이트에 저장하는 등의 행동을 하지 않으므로, 호출하는 곳에서 데이터 스토리지에 무조건 저장 시켜줘야 함!!!
---코스튬 아이템을 구매할 때만 사용됨
function local_class:change_dollar_immediately(diff)
	self.dollar_val = self.dollar_val + diff

	-- 달러 소모 이벤트 발송
	message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { self.dollar_remove_event }))

	-- 달러 값 UI에 표시
	if self.dollar_ui_label ~= nil then
		self.dollar_ui_label.text = self.dollar_val + self.temporary_dollar_val
	end

	return self.dollar_val
end

function local_class:get_dollar()
	return self.dollar_val + self.temporary_dollar_val
end

-- 데이터 스토리지에서 데이터를 가져옴
function local_class:get_custom_data(key)
	if self.data_storage == nil then
		self:load_data_storage()
	end
	return self.data_storage:get_data(key)
end

-- 데이터 스토리지에 추가 데이터를 저장함
function local_class:set_custom_data_async(key, value)
	self.data_storage:set_data_async(key, value)
end

-- 현재 멤버가 입고있는 코스튬이 기본 코스튬인지 확인
function local_class:is_original_costume(member_index)
	local member_binary = 2 ^ member_index
	local wearing_binary = self:get_custom_data(self.wearing_clothes_data_key)

	if wearing_binary < 0 then
		return true
	end

	return (member_binary & wearing_binary) == 0
end

-- 현재 입고있는 코스튬에 대한 정보(바이너리)를 가져옴
function local_class:get_wearing_binary()
	local binary = self:get_custom_data(self.wearing_clothes_data_key)

	if binary < 0 then
		return 0
	else
		return binary
	end
end

-- 현재 파티에 있는 리나 캐릭터 받아옴
function local_class:get_lina()
	if self:is_original_costume(0) then
		return get_character('lina')
	else
		return get_character('costume_lina')
	end
end

-- 현재 파티에 있는 가우리 캐릭터 받아옴
function local_class:get_goury()
	if self:is_original_costume(1) then
		return get_character('goury')
	else
		return get_character('costume_goury')
	end
end

-- 현재 파티에 있는 제로스 캐릭터 받아옴
function local_class:get_xellos()
	if self:is_original_costume(2) then
		return get_character('xellos')
	else
		return get_character('costume_xellos')
	end
end

function local_class:on_stage_end_event(e)
	self.data_storage:set_data(self.dollar_data_key, self.dollar_val)
end

return {
	create = function()
		return local_class();
	end
}
