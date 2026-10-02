local local_class = newclass('SubStageQueenShipCrosselleController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_plasma_bomber = function()
		return get_character('plasma_bomber')
	end

	self.plasma_bomber_run_enabled = true
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.opening_routine, self)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:opening_routine()
	local crosselle_quest_id = 319
	local crosselle_quest = user_progress:GetStartedQuest(crosselle_quest_id)

	if crosselle_quest == nil then
		-- 퀘스트 받기 전에 스테이지 진입할 일은 없지만 일단 막아놓음
		return
	end

	local crosselle_host = get_character('crosselle')

	character_util.convert_to_manual_character(crosselle_host)

	if crosselle_quest.IsComplete then
		stage_launch_util.default_launch_with_marker_name('clear_start', true)
	elseif crosselle_quest.InnerProgress >= 1 and crosselle_quest.InnerProgress <= 4 then
		stage_launch_util.default_launch_with_marker_name(
				's' .. (crosselle_quest.InnerProgress + 1) .. '_start', true)
	end

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:on_stage_loaded(_)
	local plasma_bomber = get_character('plasma_bomber')

	local custom_data = require('Quest/Main/QueenShip/Common/CustomDataKeyConstants.lua')

	local is_dead = stage_progress_util.get_custom_data_int(custom_data.common.bomber_dead_default, 0) == 1

	if is_dead then
		-- 이벤트 발생 비활성화
		self.plasma_bomber_run_enabled = false
	else
		character_util.set_active_state(plasma_bomber, 'visible')
	end

	return true
end

function local_class:on_zone_enter_event(e)
	if self.plasma_bomber_run_enabled and
			type_util.is_zone_full_enter(e, get_party_leader(), 'plasma_bomber_run_up') then
		self.plasma_bomber_run_enabled = false
		start_coroutine(self.enter_plasma_bomber_run, self, 'up')

		return true

	elseif self.plasma_bomber_run_enabled and
			type_util.is_zone_full_enter(e, get_party_leader(), 'plasma_bomber_run_left') then
		self.plasma_bomber_run_enabled = false
		start_coroutine(self.enter_plasma_bomber_run, self, 'left')

		return true
	end

	return false
end

function local_class:enter_plasma_bomber_run(look_dir)
	local plasma_bomber = get_character('plasma_bomber')

	character_util.show_emoticon_with_data(plasma_bomber, nil,
			'notice', nil, { attach_to_fo = true, emoticon_time = { 0, 0.7, 0.1 } })

	character_util.set_direction(plasma_bomber, look_dir)

	character_util.normal_jump_async(plasma_bomber)

	music_player_util.play_sfx({
		sfx_name = '03_runaway_01', play_pos = plasma_bomber.Position, type_priority = 'gimmick', player_priority = 'npc'
	})

	wp_util.move_async(plasma_bomber, field_util.get_marker_pos('s1_exiting_invader_wp_5'),
			8, nil, { run = true, y_mode = 'floor'})

	character_util.set_active_state(plasma_bomber, 'enabled')

	-- 플라즈마 폭탄병 세팅
	local way_list = create_generic_list(CS.System.String)
	way_list:Add('1, 3')
	way_list:Add('2, 0')
	way_list:Add('3, 1')
	way_list:Add('0, 2')

	plasma_bomber.FieldObjectController = CS.Oak.FugitiveCharacterController.Create(way_list, 4, 10, nil)
	plasma_bomber.FieldObjectController.TripSfx = '02_touch_laser_cannon_01'
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
