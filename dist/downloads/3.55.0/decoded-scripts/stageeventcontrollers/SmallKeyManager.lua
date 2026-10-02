local local_class = newclass("SmallKeyManagerController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 스테이지 이름
	self.stage_name_1 = 'futurecastle_part2_1_2'
	self.stage_name_2 = 'futurecastle_part2_1_4'
	self.stage_name_3 = 'futurecastle_part2_1_5'

	-- 리소스 홀더
	self.resholder = nil

	-- 열쇠 개수 보여주는 NGUI의 라벨
	self.key_ui_label = nil

	-- 소지 중인 작은 열쇠 개수
	self.get_key_num = 0

	-- 작은 열쇠 이름
	self.key_name = 'key_'

	-- 작은 열쇠 아이템 번호
	self.key_item_id = 30033
	self.key_item_id_2 = 30034
	self.key_item_id_3 = 30035

	-- 각 스테이지 ItemDoor
	self.stage_1_doors = {'room_b_1_keydoor', 'room_b_5_keydoor', 'main_hall_door_1', 'room_a_5_keydoor',
						  'room_d_1_keydoor_1', 'room_d_1_keydoor_2', 'room_d_3_keydoor'}
	self.stage_2_doors = {'inner_key_door', 'lorain_clone_key_door', 'right_key_door'}
	self.stage_3_doors = {'beta_weapon_keydoor_1', 'beta_weapon_keydoor_2'}

	-- 각 스테이지에서 진행에 꼭 필요한 ItemDoor
	self.stage_1_must_open_doors = {'main_hall_door_1', 'room_a_5_keydoor', 'room_d_1_keydoor_1', 'room_d_1_keydoor_2'}
	self.stage_2_must_open_doors = {'inner_key_door', 'lorain_clone_key_door', 'right_key_door'}
	self.stage_3_must_open_doors = {'beta_weapon_keydoor_1', 'beta_weapon_keydoor_2'}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DoorOpenedEvent), 'on_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.resholder = CS.Foundations.ResourceHolder()

	local key_ui = nil

	coroutine.yield(self.resholder:LoadPrefabAsync(CS.Foundations.AssetName(
			"ondemand/v2_10_futurecastle_part2/ui", "futurecastle_small_key_ui"), function(p)
		key_ui = CS.NGUITools.AddChild(CS.Oak.UI.NavigationBar.Instance.gameObject, p).transform:GetChild(0)
	end))

	self.key_ui_label = CS.Utils.FindChildRecursively(key_ui.transform, 'Label'):GetComponent(typeof(CS.UILabel))
	CS.Utils.FindChildRecursively(key_ui.transform, 'Name'):GetComponent(typeof(CS.UILabel)).text = game_string:GetString('futurecastle_small_key')

	-- 플레이어 인벤토리를 확인해서 현재 열쇠 개수 표시
	local cur_key_item_id = self.key_item_id
	local doors = self.stage_1_doors
	local must_opened_doors = self.stage_1_must_open_doors

	if stage.Name == self.stage_name_2 then
		cur_key_item_id = self.key_item_id_2
		doors = self.stage_2_doors
		must_opened_doors = self.stage_2_must_open_doors
	elseif stage.Name == self.stage_name_3 then
		cur_key_item_id = self.key_item_id_3
		doors = self.stage_3_doors
		must_opened_doors = self.stage_3_must_open_doors
	end

	self.get_key_num = user:ItemCount(cur_key_item_id)
	self.key_ui_label.text = self.get_key_num

	-- 키가 중복으로 사용되어 문이 안 열리는 현상 수정을 위한 임시 코드
	if self.get_key_num == 0 then
		-- 키를 몇 개 먹었는지 확인. 키 갯수와 문 갯수와 동일하니 문 갯수로 체크
		local has_key_state_num = 0
		for i = 1, #doors do
			local has_key = stage_progress:HasItem(self.key_name .. i)
			if has_key then
				has_key_state_num = has_key_state_num + 1
			end
		end

		-- 문이 몇 개 열렸는지 확인
		local open_doors = {}
		for i = 1, #doors do
			local is_open_door = stage_progress:GetNamedData(doors[i])
			if is_open_door then
				table.insert(open_doors, doors[i])
			end
		end

		-- 먹은 키가 열린 문보다 많은 경우. 아이템이 유실된 것으로 판단.
		if has_key_state_num > #open_doors then
			local count = has_key_state_num - #open_doors
			-- 진행에 문제생기면 안 되는 문들 먼저 검사
			for i = 1, #must_opened_doors do
				if count == 0 then
					break
				end

				if not table_util.contain_value(open_doors, must_opened_doors[i]) then
					self:open_item_door(must_opened_doors[i])
					count = count - 1
				end
			end

			-- 진행에 문제생기면 안 되는 문들 다 열려 있으면 문 전체 검사
			if count ~= 0 then
				for i = 1, #doors do
					if count == 0 then
						break
					end

					if not table_util.contain_value(open_doors, doors[i]) then
						self:open_item_door(doors[i])
						count = count - 1
					end
				end
			end
		end
	end
end

function local_class:open_item_door(door_name)
	stage_progress:SetNamedData(door_name, true)
	-- 문을 Open상태로 바꾸는 걸 AttachTo에서 하기 때문에 해당 함수를 불러주기 위해 FieldObjectBehaviour를 뗐다 붙인다.
	local key_door_field_object = get_field_object(door_name)
	local back_behaviour = key_door_field_object.FieldObjectBehaviour
	key_door_field_object.FieldObjectBehaviour = CS.Oak.NullFieldObjectBehaviour()
	key_door_field_object.FieldObjectBehaviour = back_behaviour
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DoorOpenedEvent))

	self.key_ui_label = nil

	if self.resholder ~= nil then
		self.resholder:Dispose()
		self.resholder = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ItemGetEvent) then
		self:on_item_get_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.DoorOpenedEvent) then
		self:on_door_opened_event(e)
	end

	return false
end

function local_class:on_item_get_event(e)
	-- 열쇠 개수 증가 적용
	local cur_key_item_id = self.key_item_id

	if stage.Name == self.stage_name_2 then
		cur_key_item_id = self.key_item_id_2
	elseif stage.Name == self.stage_name_3 then
		cur_key_item_id = self.key_item_id_3
	end

	if e.Getter == user_party_leader and e.Item.ItemId == cur_key_item_id then
		self.get_key_num = self.get_key_num + 1
		self.key_ui_label.text = self.get_key_num
	end
end

function local_class:on_door_opened_event(e)
	local cur_door = get_field_object(e.DoorHandleName)

	-- ItemDoor일 경우에만 열쇠 개수 감소 적용
	if lua_helper.type_compare(cur_door.FieldObjectBehaviour, CS.Oak.ItemDoorBehaviour) then
		self.get_key_num = self.get_key_num - 1
		self.key_ui_label.text = self.get_key_num
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
