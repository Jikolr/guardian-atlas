local local_class = newclass('ShortStoryLahnBook')

function local_class:init()
	self.book_data = nil

	self.index_data_key = 'index_data_key'

	-- ShortStoryLahnBookSetting.lua에 저장된 데이터
	self.book_data = nil

	self.data_storage = nil

	self.quest_id = 7000702

	self.table_form_data = nil

	self.bit_form_data = 0

	-- 아이템 획득 커스텀 이벤트
	self.item_update_event = 'short_story_lahn_book_item_update'

	-- 마지막으로 업데이트 된 아이템 정보
	-- 기본적으로 1번 탭에 1번 아이템을 출력
	self.last_update_info = {
		category_num = 1,
		item_num = 1
	}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
end

function local_class:on_stage_loaded_event(e)
	self:pre_load()
end

function local_class:pre_load()
	if self.table_form_data == nil then
		if self.book_data == nil then
			local constants = require('ShortStoryLahnBookSetting')
			self.book_data = constants['short_story_lahn_book_settings']
		end

		if self.data_storage == nil then
			local storage_create = require('utils/QuestDataStorage')
			self.data_storage = storage_create.create(self.quest_id)
		end

		self:load()
	end
end

function local_class:set_book_open_position()
	self:pre_load()
	self:claimable_star_piece_exist()
end

--- 아이템 획득 및 진행도 올릴 때 사용
function local_class:set_book_data(category_num, item_num, progress, play_narration, open_book)
	self:pre_load()

	local val = lua_helper.get_or_default(progress, self.table_form_data[category_num][item_num] + 1)
	local playnarration = lua_helper.get_or_default(play_narration, true)
	local openbook = lua_helper.get_or_default(open_book, true)

	local cur_category = self.book_data['short_story_lahn_book_category_' .. category_num]

	if cur_category ~= nil then

		local cur_item = cur_category['items']
		if cur_item ~= nil then

			-- 방어코드 : description 테이블 길이보다 progress가 커지는 것을 방지
			local desc_length = table_util.get_size(cur_item[item_num].description)
			val = unity_class.mathf.Clamp(val, 0, desc_length)

			self.table_form_data[category_num][item_num] = val

			self.last_update_info.category_num = category_num
			self.last_update_info.item_num = item_num

			if category_num == 3 then
				-- 메인은 섹션이 넘어갈때만 DB에 CustomState 저장되도록
				-- 또한 스테이지 정상적으로 나갈때도 저장하면 안됨
				-- 1. customstate 저장 예약
				-- 2. 다음 섹션 넘어가기 전에 스테이지 나가기와 같은 경우가 있을 수 있음
				local playnarration_str = playnarration and 'true' or 'false'
				local openbook_str = openbook and 'true' or 'false'

				message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { self.item_update_event, playnarration_str, openbook_str }))
			else
				-- 3이 아니면 서브 도감 기록이므로 바로바로 DB에 CustomState 저장
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.save, self, playnarration, openbook))
			end
		end
	end
end

function local_class:set_book_data_async(category_num, item_num, progress, play_narration, open_book)
	self:pre_load()

	local val = lua_helper.get_or_default(progress, self.table_form_data[category_num][item_num] + 1)
	local playnarration = lua_helper.get_or_default(play_narration, true)
	local openbook = lua_helper.get_or_default(open_book, true)
	local cur_category = self.book_data['short_story_lahn_book_category_' .. category_num]

	if cur_category ~= nil then

		local cur_item = cur_category['items']
		if cur_item ~= nil then

			-- 방어코드 : description 테이블 길이보다 progress가 커지는 것을 방지
			local desc_length = table_util.get_size(cur_item[item_num].description)
			val = unity_class.mathf.Clamp(val, 0, desc_length)

			self.table_form_data[category_num][item_num] = val

			self.last_update_info.category_num = category_num
			self.last_update_info.item_num = item_num

			if category_num == 3 then
				-- 메인은 섹셕이 넘어갈때만 DB에 CustomState 저장되도록
				local playnarration_str = playnarration and 'true' or 'false'
				local openbook_str = openbook and 'true' or 'false'

				message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { self.item_update_event, playnarration_str, openbook_str }))
			else
				-- 3이 아니면 서브 도감 기록이므로 바로바로 DB에 CustomState 저장
				self:save(playnarration, openbook)
			end
		end
	end
end

--- 도감 기록 등 다른 연출 없이 customstate만 저장하는 용도
function local_class:save_data_only()
	self.bit_form_data = self:encode_data(self.table_form_data)
	self.data_storage:set_data(self.index_data_key, self.bit_form_data)
end

function local_class:save_data_async_only()
	self.bit_form_data = self:encode_data(self.table_form_data)
	self.data_storage:set_data_async(self.index_data_key, self.bit_form_data)
end

--- 도감 정보 테이블 폼으로 얻기
function local_class:get_book_data()
	self:pre_load()

	return self.table_form_data
end

-- 마지막으로 업데이트 된 아이템의 정보 얻기
function local_class:get_last_updated_item_data()
	return self.last_update_info
end

-- states에 전달 되어야 하는 모든 정보를 일괄적으로 반환
function local_class:get_all_states_data()
	return {self:get_book_data(), self:get_last_updated_item_data()}
end

--- 얻을 스타피스가 있다면 래드닷 표시
function local_class:claimable_star_piece_exist(update_last_info)
	local updatelastinfo = lua_helper.get_or_default(update_last_info, true)

	for i = 1, table_util.get_size(self.table_form_data) do
		local cur_category = self.book_data['short_story_lahn_book_category_' .. i]
		local all_cleared = true
		local item_num = table_util.get_size(self.table_form_data[i])

		for j = 1, item_num do
			if cur_category.star_piece_key ~= nil then

				-- 해당 카테고리의 아이템 중 진행도가 최대가 아닌 것이 하나라도 있다면 다음 카테고리로 이동
				if table_util.get_size(cur_category.items[j].description) ~= self.table_form_data[i][j] then
					all_cleared = false
					break
				end

			-- 만약 해당 카테고리에 얻을 스타피스가 없다면 다음 카테고리로 이동
			elseif cur_category.star_piece_key == nil then
				break
			end
		end

		-- 모든 진행도가 최대고 아직 스타피스를 얻지 않았다면 래드닷 표시
		if all_cleared == true and cur_category.star_piece_key ~= nil then
			local got_star_piece = star_piece_util.has_star_piece(cur_category.star_piece_key)
			if got_star_piece == false then

				-- 얻을 스타피스가 있다면 다음에 도감 열 때 해당 카테고리로 이동
				if updatelastinfo == true then
					self.last_update_info.category_num = i
					self.last_update_info.item_num = 1
				end

				return true
			end
		end
	end

	return false
end

function local_class:save(play_narration, open_book)
	self.bit_form_data = self:encode_data(self.table_form_data)

	-- 커스텀 키 스테이지 나가지 않고도 바로 저장 되게 변경
	self:apply_custom_state_immediately(self.index_data_key, self.bit_form_data, play_narration, open_book)
end
-- int형 data가 테이블 형태로 담김
function local_class:load()
	local bit_form_data = self.data_storage:get_data(self.index_data_key)

	self.table_form_data = self:decode_data(bit_form_data)
end

--- table_form_data 값들을 int로 인코딩 후 반환
--- 32 bit
function local_class:encode_data(table_form_data)
	local data = 0
	local shift_cnt = 0
	for i = 1, table_util.get_size(self.book_data) do
		local cur_category = self.book_data['short_story_lahn_book_category_' .. i]

		if cur_category ~= nil then
			for j = 1, table_util.get_size(cur_category.items) do
				-- 각 소분류 아이템의 최대 진행도 수 많큼 동적으로 공간 활용
				local desc_size = table_util.get_size(cur_category.items[j].description)
				local digit_num = self:get_decimal_digit_num_in_binary_form(desc_size)

				data = data | (table_form_data[i][j] << shift_cnt)
				shift_cnt = shift_cnt + digit_num
			end
		end
	end

	return data
end

--- bit_form_data를 받아 table_form_data로 변경
function local_class:decode_data(bit_form_data)
	local data = (bit_form_data ~= -1) and math.tointeger(bit_form_data) or 0
	if data == nil or self.book_data == nil then
		return nil
	end

	local container = {}
	local num = 1
	for i = 1, table_util.get_size(self.book_data) do
		table.insert(container, {})
		local cur_category = self.book_data['short_story_lahn_book_category_' .. i]

		if cur_category ~= nil then
			for j = 1, table_util.get_size(cur_category.items) do
				local desc_size = table_util.get_size(cur_category.items[j].description)
				local digit_num = self:get_decimal_digit_num_in_binary_form(desc_size)

				-- 순회 할떄 마다 2배씩 커지는 수
				local cur_num = 1

				-- 테이블에 담길 수 (최종값)
				local result_num = 0

				for k = 1, digit_num do
					if (data & num) == num then
						result_num = result_num + cur_num
					end
					cur_num = cur_num * 2
					num = num << 1
				end

				table.insert(container[i], result_num)
			end
		end
	end

	return container
end

-- 스테이지 나가지 않아도 커스텀 스테이트가 바로 저장 되도록 하기
function local_class:apply_custom_state_immediately(key_name, val, play_narration, open_book)
	local quest_progress = user_progress:GetStartedQuest(self.quest_id)
	local save_success = true
	local on_success = function (res)

		-- 아이템 업데이트 이벤트 발송
		local playnarration = play_narration and 'true' or 'false'
		local openbook = open_book and 'true' or 'false'

		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { self.item_update_event, playnarration, openbook }))

		save_success = true
	end

	-- 먼저 custom state 를 set 한다.
	local fail_count = 0
	while true do
		local r = CS.Oak.IQuestEventControllerExtensions.SetCustomState(nil, quest_progress, key_name, val)
		coroutine.yield(r)
		coroutine.yield(nil)
		-- on_error 콜백을 안받아서 CustomState 가 실제로 변경되었는지로 체크해야 한다..
		save_success = true

		if quest_progress:GetCustomState(key_name) ~= val then
			save_success = false
		end

		if not save_success then
			fail_count = fail_count + 1
			CS.UnityEngine.Debug.LogError("ShortStoryLahnBook : SetCustomState Retry")
			wait_for_sec(5.0 + fail_count)
		else
			break
		end
	end

	fail_count = 0
	while true do
		save_success = false
		local r = CS.Oak.NetworkManager.ApiConnection:SendProgressQuest(stage.StageId, quest_progress.QuestId, quest_progress.InnerProgress, nil)
		r:Then(on_success)
		coroutine.yield(r:SuppressDefaultErrorHandler())
		coroutine.yield(nil)
		if not save_success then
			fail_count = fail_count + 1
			CS.UnityEngine.Debug.LogError("ShortStoryLahnBook : SendProgressQuest Retry")
			wait_for_sec(5.0 + fail_count)
		else
			break
		end
	end
end

function local_class:get_decimal_digit_num_in_binary_form(num)
	local n = 1
	local cnt = 0

	while true do
		n = n * 2
		cnt = cnt + 1
		if n > num then
			break
		end
	end

	return cnt
end


--- 디버깅용 함수
--- 모든 아이템을 도감에 추가 + 모든 아이템의 진행도를 최대로
function local_class:complete_lahn_book(play_narration, open_book)
	self:pre_load()

	local playnarration = lua_helper.get_or_default(play_narration, true)
	local openbook = lua_helper.get_or_default(open_book, true)

	for i = 1, table_util.get_size(self.book_data) do
		local cur_category = self.book_data['short_story_lahn_book_category_' .. i]

		if cur_category ~= nil then
			for j = 1, table_util.get_size(cur_category.items) do
				local cur_item = cur_category['items']
				if cur_item ~= nil then
					local desc_length = table_util.get_size(cur_item[j].description)
					self.table_form_data[i][j] = desc_length
				end
			end
		end
	end
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.save, self, playnarration, openbook))
end


return {
	create = function()
		return local_class();
	end
}
