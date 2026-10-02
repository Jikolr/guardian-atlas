local local_class = newclass('QueenShipEvCoreController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 엘레베이터 코어 아이템 Id
	self.core_item_id = 20749

	local custom_keys = require('Quest/Main/QueenShip/Common/CustomDataKeyConstants.lua')
	local common_keys = custom_keys.common

	-- 엘레베이터 코어 StageCustom Key
	self.ev_core_key = common_keys.core_count

	-- 보물상자를 열었을 때 ItemGetEvent를 볼 CoreBox 데이터 세트
	-- ['StageName'] = { 'CoreBoxName' .. }
	self.ev_core_info = {
		['queenship_substage_treasure'] = { 'core_box' },
		['queenship_substage_farm'] = { 'core_box' },
		['queenship_substage_crosselle'] = { 'core_box' },
		['queenship_1_4'] = { 'core_box' },
		['queenship_1_5'] = { 'core_box' },
		['queenship_1_6'] = { 'core_box' },
		['passage_15_1'] = { 'core_box' },
		['passage_15_2'] = { 'core_box' },
		['passage_15_3'] = { 'core_box' },
		['passage_15_4'] = { 'core_box' },
		['nightmare_queenship_3'] = { 'core_box' }
	}

	self.current_data = nil
end

function local_class:load_resource()
	self.current_data = self.ev_core_info[stage.Name]

	message_system:Subscribe(self, typeof(CS.Oak.TreasureOpenScreenPlayEndEvent), 'on_treasure_open_screen_play_end_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

function local_class:on_treasure_open_screen_play_end_event(e)
	if self.current_data == nil then
		return false
	end

	for i = 1, #self.current_data do
		local chest = get_field_object(self.current_data[i])

		if lua_helper.reference_equals(e.Target, chest) then
			sp_util.play_normal_screenplay(self.get_core, self)
			return true
		end
	end
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:get_core()
	-- 아이템 획득 연출
	yield_return_func(CS.Oak.CommonScreenplay.ItemGetEvent,
			{ ItemId = 20749, NotForInventory = true },
			'qs_main_elevator_core_title',
			'qs_main_elevator_core_sub_title',
			'qs_main_elevator_info'
	)

	-- 코어 UI 갱신
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'refresh_resource_ui' }))
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.TreasureOpenScreenPlayEndEvent))

	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
