local local_class = newclass('DemonShire1At1Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 소히 가져오기
	self.get_sohee = function() return get_character('sohee') end

	-- 백작 딸 가져오기
	self.get_count_daughter = function() return get_character('count_daughter') end

	-- 메인 퀘스트 id
	self.main_quest_id = 286
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

function local_class:on_battle_actions_changed_event(e)
	if e.Target ~= user_party.Leader then
		return false
	end

	local character_spec_id = 304101
	if user_util.has_knight_male() then
		character_spec_id = 304100
	end

	get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateStoryCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)
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

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))
end

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
	local start_stage_event = function(dir, pos, directional_stage_entry, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')
			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position,
				leader.Direction, game_string:GetString(stage.Name)))
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	-- 퀘스트정보가 없거나 클리어 했다면 기본 위치에서 시작
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		change_leader_character()
		start_stage_event('up', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 0 then
		change_leader_character()
		start_stage_event('up', field:GetMarker('default_start').position, false, false)
	elseif main_quest_progress.InnerProgress == 1 then
		change_leader_character()
		start_stage_event('up', field:GetMarker('default_start').position, false, true)
	elseif main_quest_progress.InnerProgress == 2 then
		change_leader_character()
		if user_progress:IsStageCleared(stage.Name) then
			start_stage_event('down', field:GetMarker('office_outer').position + vector(0, 0, -1),
					true, true)
		else
			start_stage_event('down', field:GetMarker('office_center').position + vector(0, 0, -2),
					true, true)
		end
	else
		change_leader_character()
		start_stage_event('up', field:GetMarker('default_start').position, true, true)
	end


	if user_progress:IsStageCleared(stage.Name) then
		local oneline_npcs = {}
		table.insert(oneline_npcs, get_character('demon_kid_1'))
		table.insert(oneline_npcs, get_character('demon_civilian_1'))
		table.insert(oneline_npcs, get_character('vampire_civilian_1'))
		table.insert(oneline_npcs, get_character('vampire_civilian_2'))

		for _, npc in ipairs(oneline_npcs) do
			character_util.remove_anim_and_emotion(npc)
			character_util.set_position(npc, vector(999, 0, 999))
			character_util.set_active_state(npc, 'disabled')
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
