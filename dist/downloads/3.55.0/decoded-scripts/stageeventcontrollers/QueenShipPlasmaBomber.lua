local local_class = newclass('QueenShipPlasmaBomberController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	local custom_keys = require('Quest/Main/QueenShip/Common/CustomDataKeyConstants.lua')
	local common_keys = custom_keys.common

	-- 플라즈마 폭탄병 처치 여부 저장용 커스텀 데이터 키
	local bomber_dead_key = common_keys.bomber_dead_default

	-- TODO : 모든 스테이지에 폭탄병 설치 후 데이터 갱신
	self.bomber_infos = {
		['queenship_1_2'] = {
			--[''] = bomber_dead_key + 1,
		},
		['queenship_1_3'] = {
			['plasma_bomber'] = bomber_dead_key,
		},
		['queenship_1_4'] = {
			['plasma_bomber_1'] = bomber_dead_key,
			['plasma_bomber_2'] = bomber_dead_key + 1,
		},
		['queenship_1_5'] = {
			['plasma_bomber_1'] = bomber_dead_key,
			['plasma_bomber_2'] = bomber_dead_key + 1,
		},
		['queenship_1_6'] = {
			['plasma_bomber'] = bomber_dead_key,
		},
		['passage_15_2'] = {
			['plasma_bomber_1'] = bomber_dead_key,
		},
		['queenship_substage_crosselle'] = {
			['plasma_bomber'] = bomber_dead_key,
		},
		['queenship_substage_duplication_lab'] = {
			['plasma_bomber'] = bomber_dead_key,
		},
		['nightmare_queenship_2'] = {
			['plasma_bomber'] = bomber_dead_key,
		},
		['nightmare_queenship_3'] = {
			['plasma_bomber_1'] = bomber_dead_key,
			['plasma_bomber_2'] = bomber_dead_key + 1,
		},
	}

	-- 폭탄 개수 저장용 커스텀 데이터 키
	self.bomb_count_data_key = common_keys.bomb_count

	self.bomb_item_id = 20748

	self.wait_before_get_bomb = false
end

function local_class:load_resource()
	local bomber_info = self.bomber_infos[stage.Name]

	if bomber_info == nil then
		return
	end

	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_item_get_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(e)
	self:check_done_condition()
end

function local_class:on_field_object_destroyed_event(e)
	local bomber_info = self.bomber_infos[stage.Name]
	local data_key = bomber_info[e.FieldObject.Name]

	if data_key == nil then
		return false
	end

	local is_dead = stage_progress_util.get_custom_data_int(data_key, 0) == 1

	-- StageLoaded에서 체크했지만 혹시 모르니까 (뭔가 부활 시켰다던지 등) 한번 더 체크해봄
	if is_dead then
		return false
	end

	sp_util.play_normal_screenplay(self.drop_bomb_item, self, e.FieldObject, data_key)

	return true
end

function local_class:on_item_get_event(e)
	if self.wait_before_get_bomb and
			lua_helper.reference_equals(e.Getter, get_party_leader()) and e.Item.ItemId == self.bomb_item_id then
		self.wait_before_get_bomb = false
		return true
	end

	return false
end

function local_class:drop_bomb_item(bomber, data_key)
	self.wait_before_get_bomb = true

	music_player_util.play_sfx({
		sfx_name = '02_die_villain_01', play_pos = bomber.Position, type_priority = 'gimmick', player_priority = 'npc'
	})

	local bomb_item = drop_item_util.create_item({
		pos = bomber.Position, target = bomber.Position, itemid = self.bomb_item_id,
		notforinven = true, lootstate = 'FixLooter'
	})

	bomb_item.ConsumeTarget = get_party_leader()

	-- 처치했음을 저장
	stage_progress_util.set_custom_data_async(data_key, 1)

	-- 카운트 갱신
	local bomb_count = stage_progress_util.get_custom_data_int(self.bomb_count_data_key, 0)
	stage_progress_util.set_custom_data_async(self.bomb_count_data_key, bomb_count + 1)

	while self.wait_before_get_bomb do
		coroutine.yield()
	end

	screen_util.item_get_event('qs_plasma_bomb', 'qs_plasma_bomber_bomb_title',
			'qs_plasma_bomber_bomb_subtitle', 'qs_plasma_bomber_bomb_desc')

	-- UI 갱신 하도록 이벤트 보냄
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, {'refresh_resource_ui'}))

	-- 전부 잡았는지 확인하여 구독 취소 여부 결정
	self:check_done_condition()
end

function local_class:check_done_condition()
	-- 이미 load_resource단에서 스테이지 데이터가 있는지 체크했으므로 여기서는 안해도 됨
	local bomber_info = self.bomber_infos[stage.Name]
	local is_all_dead = true

	for bomber_name, data_key in pairs(bomber_info) do
		local bomber = get_character(bomber_name)
		local is_dead = stage_progress_util.get_custom_data_int(data_key, 0)

		if is_dead == 1 then
			bomber.FieldObjectController = CS.Oak.NullFieldObjectController.Instance
			character_util.set_active_state(bomber,'disabled')
		else
			is_all_dead = false
		end
	end

	-- 모두 죽어있는 경우에는 더 이상 트래킹할 필요가 없으므로 구독 해제
	if is_all_dead then
		message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
