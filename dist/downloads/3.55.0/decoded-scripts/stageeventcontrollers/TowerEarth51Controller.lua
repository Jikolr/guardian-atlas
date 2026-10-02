-- 지속성 던전 51층 전용 컨트롤러.
-- 단순 연출용으로 제작되었으니, 다른 스테이지에서는 쓰지 마시오.
local local_class = newclass('TowerEarth51Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 스테이지 진행 상태
	self.progress = { 
		none = 1, 
		-- 던전 진행 중.
		playing = 2, 
		-- 모든 전투 클리어
		finish = 3 
	}

	self.magic_circle_effect_cache = {}
	self.magic_portal_data = {
		total_count = 2,
		effect_name = 'MagicCircle_AppearIdle',
		effect_scales = { 0.65, 0.75 },
		active_state = { true, false },
		spawn_pos_marker_name = { 'magic_portal_1_enter', 'magic_portal_2_enter' },
		target_event_zone_names = { 'magic_portal_1', 'magic_portal_2' },
		target_exit_marker_names = { 'magic_portal_1_exit', 'magic_portal_2_exit' },
	}

	self.num_cleared_battle = 0

	self.current_progress = self.progress.none

	function self.get_magic_circle_effect()
		return unity_object_pool.GetOrCreate(self.magic_portal_data.effect_name)
	end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')

	return util.cs_generator(self.on_load_local, self)
end

function local_class:on_load_local()
	quest_util.load_pool_resource(self.magic_portal_data.effect_name)
end

function local_class:on_stage_start_event(e)
	self.current_progress = self.progress.playing

	local spawn_pos = field_util.get_marker_pos(self.magic_portal_data.spawn_pos_marker_name[1])
	self:create_magic_circle_effect(spawn_pos, self.magic_portal_data.effect_scales[1])
end

function local_class:on_zone_enter_event(e)
	local zone_name = e.Zone.Name

	for i = 1, self.magic_portal_data.total_count do
		local target_zone_name = self.magic_portal_data.target_event_zone_names[i]
		local target_exit_marker_name = self.magic_portal_data.target_exit_marker_names[i]
		local is_portal_active = self.magic_portal_data.active_state[i]
		if zone_name == target_zone_name and
			is_portal_active and
			type_util.is_zone_full_enter(e, user_party.Leader, target_zone_name) then
			
			sp_util.start_scene(self.teleport, self, target_exit_marker_name)
		end
	end

	return false
end

function local_class:on_battle_end_event(e)
	if self.current_progress == self.progress.playing then
		self.num_cleared_battle = self.num_cleared_battle + 1

		if self.num_cleared_battle == 4 then
			sp_util.start_scene(self.second_portal_activated, self)
		end
	end

	return true
end

--function local_class:use_late_update_frame()
--	return true
--end
--
--function local_class:late_update_frame_priority()
--	return CS.Oak.UpdatePriorities.StageEvent
--end
--
--function local_class:late_update_frame(dt)
--	if self.current_progress == self.progress.playing then
--end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))

	for i = 1, #self.magic_circle_effect_cache do
		if self.magic_circle_effect_cache[i] ~= nil then
			self.magic_circle_effect_cache[i]:Dispose()
			self.magic_circle_effect_cache[i] = nil
		end
	end

	self.magic_circle_effect_cache = nil

	self.magic_portal_data = nil

	self.current_progress = self.progress.none
	self.cs_controller = nil
end

function local_class:create_magic_circle_effect(position, scale)
	local effect_pool = self.get_magic_circle_effect()
	local magic_circle_effect = effect_pool:Instantiate(position)
	magic_circle_effect.transform.localScale = vector(scale, scale, scale)
	table.insert(self.magic_circle_effect_cache, magic_circle_effect)
end

function local_class:second_portal_activated()
	local second_portal_spawn_pos = field_util.get_marker_pos(self.magic_portal_data.spawn_pos_marker_name[2])

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	camera_util.move_async(second_portal_spawn_pos, 0)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	-- 두 번째 포탈 생성
	music_player_util.play_sfx_one_shot('02_magic_shield_01')
	self:create_magic_circle_effect(second_portal_spawn_pos, self.magic_portal_data.effect_scales[2])
	self.magic_portal_data.active_state[2] = true
	
	wait_for_sec(2.9)

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	camera_util.return_to_leader(0)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')
end

-- 텔레포트 연출
function local_class:teleport(target_marker)
	local leader = get_party_leader()

	character_util.set_active_state(leader, 'visible')

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local marker = field:GetMarker(target_marker)

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'npc' })

	character_util.spine_set_alpha_fade(leader, 0, 0.5)

	wait_for_sec(0.2)

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')
	party_util.align_party(marker.position, 'down', 0, 'arc')
	camera_util.return_to_leader(0)

	party_util.stop_and_disable_control()

	character_util.spine_set_alpha_fade(leader, 1, 0.5)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	party_util.reset_controllers()
	field_ui_manager:Show()

	character_util.set_active_state(leader, 'enabled')
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
