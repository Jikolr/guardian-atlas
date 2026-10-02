local local_class = newclass('FutureCastleStewCodeController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 상자들
	self.get_tables = function()
		local results = {}
		for i = 1, 4 do
			local tmp = get_field_object('food_code_ingred_'..i)
			results[tmp] = i
		end
		return results
	end

	self.get_recipe_table = function() return get_field_object('food_code_table') end

	-- 스위치들
	self.get_switches = function()
		local results = {}
		for i = 1, 4 do
			local tmp = get_field_object('food_code_sw_'..i)
			results[tmp] = i
		end
		return results
	end

	-- 문들
	self.get_doors = function()
		local results = {}
		for i = 1, 3 do
			local tmp = get_field_object('futurecastle_door_'..i)
			results[tmp] = i
		end
		return results
	end

	-- 재료들:
	self.recipe = { { 'gem_bug', '젬 벌레' }, { 'minotaurs_meat', '미노타우르스 고기' }, { 'slime_jelly', '슬라임 젤리' }, { 'lizard', '도마뱀' }}

	-- 비밀번호
	self.password = { 1, 2, 4, 3, 2, 4, 3, 1 }

	self.items = nil

	self.recipe_paper = nil

	-- 플레이어가 스위치를 켠 순서
	self.input_switch_queue = nil

	-- 정답을 맞춰서 문을 열었는지
	self.is_open_door = function()
		local doors = self:get_doors()
		for i,_ in pairs(doors) do
			if not i.FieldObjectBehaviour.IsOpen then return false end
		end
		return true
	end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	self.input_switch_queue = nil

	---[[
	if self.items ~= nil then
		for i, v in ipairs(self.items) do
			if not is_unity_null(v) then
				v:ConsumeComplete()
			end
		end
	end
	self.items = nil


	local recipe_table = self:get_recipe_table()
	recipe_table.Interactable = CS.Oak.NonInteractable.Instance

	local tables = self:get_tables()
	for i,_ in pairs(tables) do
		i.Interactable = CS.Oak.NonInteractable.Instance
	end


	if not is_unity_null(self.recipe_paper) then
		self.recipe_paper:ConsumeComplete()
		self.recipe_paper = nil
	end

	--]]
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.SwitchOnOffEvent) then
		return self:on_switch_on_off_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		return self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end
	return false
end

function local_class:on_switch_on_off_event(e)
	local input_switch_list = self:get_switches()
	if e.IsTurningOn then
		if lua_helper.reference_equals(e.Stepper, user_party_leader) then
			for i, _ in pairs(input_switch_list) do
				local input_switch = i
				if lua_helper.reference_equals(e.SwitchObject, input_switch) then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.switched_input, self, i))
					return true
				end
			end
		end
	end

	return false
end

function local_class:on_stage_start_event(e)
	self.input_switch_queue = { }
	self.items = { }


	local boxes = self:get_tables()
	local item_data = CS.Oak.GameDataService.GetData('ItemData')

	for i,v in pairs(boxes) do
		self.items[v] = drop_item_util.create_item(
				{ pos = i.Position + unity_class.vector3.up, itemid = item_data:GetSpec(self.recipe[v][1]).Id, lootstate = 'dontfindlooter'
				, notforinven = true, skip_text = true })
		i.Interactable = CS.Oak.PublishInteractable.Create()
	end

	local recipe_table = self:get_recipe_table()
	self.recipe_paper = drop_item_util.create_item(
			{ pos = recipe_table.Position + 1 * unity_class.vector3.up, itemid = item_data:GetSpec('paper_piece').Id, lootstate = 'dontfindlooter'
			, notforinven = true, skip_text = true })
	recipe_table.Interactable = CS.Oak.PublishInteractable.Create()

	return true
	-- 20022 : paper_piece
	--[[
	self.journal = drop_item_util.create_item(
			{ pos = self.journal_interactable.Position + 0.5 * unity_class.vector3.up, itemid = 20022, lootstate = 'dontfindlooter'
			, notforinven = true, skip_text = true })
	self.journal_interactable = get_field_object('sohee_journal_interactable')
	--]]
	-- self.journal_interactable.Interactable = CS.Oak.PublishInteractable.Create()
end

function local_class:on_interact_event(e)
	local tables = self:get_tables()
	local recipe_table = self:get_recipe_table()

	if lua_helper.reference_equals(e.Target, recipe_table) then
		sp_util.play_normal_screenplay(field_ui_util.show_narration_async,{ key = 'futurecastle_stew_code_1' } )
		return true
	else
		for i,v in pairs(tables) do
			if lua_helper.reference_equals(e.Target, i) then
				speech_bubble_util.show_speech_bubble( i, { key = 'futurecastle_stew_code_'..self.recipe[v][1] } )
				return true
			end
		end
	end
	return false
end

-- 플레이어가 스위치를 누름
function local_class:switched_input(theswitch)
	local input_switch = theswitch
	local index = self:get_switches()[input_switch]

	-- 이미 문을 열었으면 순서 체크는 하지 않는다.
	if self:is_open_door() then
		return
	end

	-- 플레이어가 킨 화로의 순서를 queue로 등록한다.
	table.insert(self.input_switch_queue, index)
	if #self.input_switch_queue > #self.password then
		table.remove(self.input_switch_queue, 1)
	end

	local is_answer = self:check_password()
	if is_answer then
		-- 문이 열림
		local door = self.get_doors()

		camera_util.move(user_party_leader.Position + 7 * unity_class.vector3.right, 1)

		for i,_ in pairs(door) do
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(i.Name, false))
		end

		wait_for_sec(2.5)

		camera_util.return_to_leader(1)
	end
end

-- 플레이어가 켠 화로의 순서와 정답이 일치하는지 확인
function local_class:check_password()
	if #self.input_switch_queue ~= #self.password then
		return false
	end

	for i = 1, #self.input_switch_queue do
		local user_num = self.input_switch_queue[i]
		local password_num = self.password[i]

		if user_num ~= password_num then
			return false
		end
	end

	return true
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
