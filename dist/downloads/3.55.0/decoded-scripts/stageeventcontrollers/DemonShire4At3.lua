local local_class = newclass('DemonShire4At3Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 카메라 그리드 이름
	self.square_camera_grid_name = 'square'

	-- 기사
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 소히
	self.get_sohee = function()
		return get_character('sohee')
	end

	-- 백작의 딸
	self.get_count_daughter = function()
		return get_character('count_daughter')
	end

	-- 후일담 이벤트 npc
	self.get_event_npc = function(event_num, npc_num)
		return get_character(string.format('event_npc_%d_%d', event_num, npc_num))
	end

	-- 메인 퀘스트 id
	self.main_quest_id = 286

	self.background_sfx = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	yield_return(unity_object_pool, 'WaitAll')
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	self:stop_background_sfx()

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_battle_actions_changed_event(e)
	if e.Target ~= user_party.Leader then
		return false
	end

	local character_spec_id = 1
	if user_util.has_knight_male() then
		character_spec_id = 2
	end

	get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)
end

function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, self.square_camera_grid_name) then
		self:play_square_background_sfx()
		return true
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, self.square_camera_grid_name) then
		self:fade_out_background_sfx()
		return true
	end

	return false
end
--endregion

function local_class:pre_setting()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 메인 캐릭터를 기사로 교체하는 함수
	local change_leader_character = function(party_member)
		-- 기사를 리더로
		local leader = self.get_knight()
		character_util.set_active_state(leader, 'enabled')
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		character_util.convert_to_manual_character(leader, param, true)

		-- 시작할 때 파티멤버로 추가해줘야할 npc들이 있다면 넣어줌.
		if party_member ~= nil then
			for i = 1, #party_member do
				character_util.set_active_state(party_member[i], 'enabled')
				character_util.convert_to_party_member(party_member[i], user_party, true)
			end
		end
	end

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, directional_stage_entry, play_stage_music, fade)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)
		local fade_screen = lua_helper.get_or_default(fade, true)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			if fade_screen then
				screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
				screen_util.fade_in_circular(1, 'linear')
			end
			stage_launch_util.directional_stage_entry(leader.Position, leader.Direction,
				game_string:GetString(stage.Name), true, play_stage_music)
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	-- 퀘스트정보가 없거나 클리어 했다면 기본 위치에서 시작
	if main_quest_progress == nil then
		change_leader_character()
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.IsComplete then
		change_leader_character({ self.get_sohee() })
		start_stage_event('right', field:GetMarker('s32_start_marker').position, true, false)
	elseif main_quest_progress.InnerProgress == 29 then
		change_leader_character({ self.get_sohee() })
		start_stage_event('up', field:GetMarker('default_start').position, false, false, false)
	elseif main_quest_progress.InnerProgress == 30 then
		change_leader_character()
		start_stage_event('up', field:GetMarker('default_start').position, false, true, false)
	elseif main_quest_progress.InnerProgress == 31 then
		change_leader_character()
		start_stage_event('up', field:GetMarker('default_start').position, false, false, false)
	else
		change_leader_character({ self.get_sohee() })
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	end
end

--region background_sfx
function local_class:play_square_background_sfx()
	self:stop_background_sfx()
	self.background_sfx = music_player_util.play_sfx({
		sfx_name = '01_amb_city_03', loop = true, type_priority = 'loop', player_priority = 'default'
	})
end

function local_class:fade_out_background_sfx()
	if self.background_sfx then
		self.background_sfx:FadeOut()
		self.background_sfx = nil
	end
end

function local_class:stop_background_sfx()
	if self.background_sfx then
		self.background_sfx:Stop()
		self.background_sfx = nil
	end
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
