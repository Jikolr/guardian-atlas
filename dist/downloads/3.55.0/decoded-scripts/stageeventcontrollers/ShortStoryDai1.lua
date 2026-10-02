local local_class = newclass('ShortStoryDai1Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
	self.main_quest_id = 7001401

	self.party_switching_complete = false

	self.get_fx_crack = function()
		return unity_object_pool.GetOrCreate('fx_space_cracked')
	end

	self.crack_effects = nil

	self.is_npc_eat_sound_zone_1_enter = false
	self.is_npc_eat_sound_zone_2_enter = false

	self.npc_eat_sound = {}
	self.market_sound = nil
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.CompleteSwitchingPartyMemberEvent),
			'on_complete_switching_party_member_event')
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	quest_util.load_pool_resource('fx_space_cracked')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	--TODO: 여기서 각 섹션별 시작 연출
	start_coroutine(self.directing_start_event, self)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CompleteSwitchingPartyMemberEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	if self.crack_effects ~= nil then
		for i = 1, #self.crack_effects do
			drop_item_util.dispose_item(self.crack_effects[i])
		end
	end

	self.crack_effects = nil

	for idx = 1, 2 do
		if self.npc_eat_sound[idx] ~= nil then
			music_player_util.stop_sfx(self.npc_eat_sound[idx])
			self.npc_eat_sound[idx] = nil
		end
	end

	if self.market_sound ~= nil then
		self.market_sound:FadeOut(1)
		self.market_sound = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, 'market_grid') then
		self.market_sound = music_player_util.play_sfx({
			sfx_name = '01_crowd_buzz_03', loop = true, type_priority = 'loop', player_priority = 'default'
		})
	end
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, 'market_grid') then

		if self.market_sound ~= nil then
			self.market_sound:FadeOut(1)
			self.market_sound = nil
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, get_party_leader(), 'eat_sound_npc_zone_1') then
		self.is_npc_eat_sound_zone_1_enter = false

		if self.npc_eat_sound[1] ~= nil then
			music_player_util.stop_sfx(self.npc_eat_sound[1])
		end

		return true
	elseif type_util.is_zone_full_leave(e, get_party_leader(), 'eat_sound_npc_zone_2') then
		self.is_npc_eat_sound_zone_2_enter = false

		if self.npc_eat_sound[2] ~= nil then
			music_player_util.stop_sfx(self.npc_eat_sound[2])
		end

		return true
	end

	return false
end

function local_class:on_complete_switching_party_member_event(_)
	self.party_switching_complete = true

	return true
end

function local_class:on_stage_loaded_event(_)
	local crack_marker_names = {
		'main_s2_meet_maid_crack',
		'main_s2_meet_swindler_crack',
		'main_s2_villager_crack',
		'village_crack_1',
		'main_s2_farmer_crack',
		'main_s6_pond_crack',
	}

	self.crack_effects = {}

	for i = 1, #crack_marker_names do
		local crack_pos = field_util.get_marker_pos(crack_marker_names[i])
		local crack_effect = self.get_fx_crack():Instantiate(crack_pos)
		table.insert(self.crack_effects, crack_effect)
	end

	return true
end

function local_class:on_zone_enter_event(e)
	--region 낚시 서브 이벤트
	local brazier = get_field_object('fishing_brazier')
	if type_util.is_zone_full_enter(e, brazier, 'fishing_intro_zone') then
		message_system:Send(brazier, CS.Oak.GimmickResetEvent.Instance)
		return true
	end
	--endregion

	local eat_npc_1 = get_character('s3_oneline_npc_7')
	local eat_npc_2 = get_character('s3_oneline_npc_1')

	if type_util.is_zone_full_enter(e, get_party_leader(), 'eat_sound_npc_zone_1')
			and not self.is_npc_eat_sound_zone_1_enter then
		self.is_npc_eat_sound_zone_1_enter = true
		self.npc_eat_sound[1] = music_player_util.play_sfx({
			sfx_name = '03_equipping_01', parent = eat_npc_1, max_distance = 2,
			loop = true, type_priority = 'loop', player_priority = 'npc', fade_in_time = 1
		})

		return true
	elseif type_util.is_zone_full_enter(e, get_party_leader(), 'eat_sound_npc_zone_2')
			and not self.is_npc_eat_sound_zone_2_enter then
		self.is_npc_eat_sound_zone_2_enter = true
		self.npc_eat_sound[2] = music_player_util.play_sfx({
			sfx_name = '03_equipping_01', parent = eat_npc_2, max_distance = 4,
			loop = true, type_priority = 'loop', player_priority = 'npc', fade_in_time = 1
		})

		return true
	end

	return false
end

function local_class:directing_start_event()
	-- FIXME : 여기서 self.party_switching_complete를 대기해야 하는가?

	-- FIXME : PS-11337 "임시 처리!!!!"
	-- 루 디버프 이펙트가 남아있어 섹션 1 전투 시작 시 디버프 이펙트가 남아있는 현상 수정
	-- 기존 파티원들을 멀리 보내서 이펙트가 보이지 않도록 임시로 수정
	local origin_party = party_util.get_origin_party()

	for i = 1, #origin_party do
		character_util.set_position(origin_party[i], vector(999, 0, 999))
	end

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)
		wait_for_sec(1)

		-- 시작 연출을 한다면 연출
		screen_util.fade_in(0, unity_class.color.black, 'linear')
		screen_util.fade_in_circular(1, 'linear')

		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position + direction_util.to_vector3(dir),
				leader.Direction, game_string:GetString(stage.Name)))

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	end

	local just_publish_stage_start = function(play_stage_music)
		message_system:Publish(CS.Oak.StageStartEvent.Instance)

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end
	end

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local inner_progress = main_quest_progress.InnerProgress

	if main_quest_progress.IsComplete then
		start_stage_event('right', field:GetMarker('default_start').position, true)
	elseif inner_progress == 0 then
		just_publish_stage_start(false)
	elseif inner_progress == 2 then
		start_stage_event('right', field:GetMarker('default_start').position, true)
	elseif inner_progress == 5 then
		just_publish_stage_start(true)
	else
		start_stage_event('right', field:GetMarker('default_start').position, true)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
