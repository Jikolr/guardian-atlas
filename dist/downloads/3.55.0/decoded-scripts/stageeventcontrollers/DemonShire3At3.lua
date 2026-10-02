local local_class = newclass('DemonShire3At3Controller')

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

	-- 태양 이팩트
	self.get_sun_effect = function() return unity_object_pool.GetOrCreate('fx_theater_demonshire_sun_big') end
	self.sun_effect = nil

	-- 메인 퀘스트 id
	self.main_quest_id = 286

	-- 미니게임 재접속 관련 처리
	self.minigame = nil
	self.minigame_name = 'BikeTempleRun'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.get_sun_effect()

	yield_return(unity_object_pool, 'WaitAll')

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if main_quest_progress == nil or main_quest_progress.InnerProgress >= 25 or main_quest_progress.IsComplete then
		local minigame_loaded = false

		self.minigame = mini_game_manager:GetOrCreate(self.minigame_name)
		mini_game_manager:LoadResource(self.minigame_name, stage.Name, function()
			minigame_loaded = true
		end)

		while not minigame_loaded do
			coroutine.yield()
		end

		-- 특정
		message_system:Subscribe(self, typeof(CS.Oak.MiniGameEndEvent), 'on_mini_game_end_event')
	end
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	-- 무조건 on_launch 런치에서 제어
	--TODO: 개발 상황에 따라 다르게 할 수도 있음
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

--region Event

function local_class:on_event(e)
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

function local_class:on_mini_game_end_event(e)
	if e.Name == self.minigame_name then
		-- 성공 여부 관계없이 광장으로 옮겨줌
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.game_done_routine, self))
		return true
	end

	return false
end

--endregion

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.MiniGameEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))

	-- 태양 이팩트 dispose
	if self.sun_effect then
		self.sun_effect:Dispose()
		self.sun_effect = nil
	end

	if self.minigame ~= nil then
		mini_game_manager:DisposeMiniGame(self.minigame_name)
	end
	self.minigame = nil

	self.cs_controller = nil
	self.scene = nil
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
	if main_quest_progress == nil or main_quest_progress.InnerProgress >= 25 or main_quest_progress.IsComplete then
		change_leader_character()
		party_util.position_party(field:GetMarker('default_start').position, 'right', 'linear')

		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		message_system:Publish(CS.Oak.StageStartEvent.Instance)

		coroutine.yield()

		field_ui_manager:Hide()
		screen_util.fade_out_async(0, unity_class.color.black, 'linear')
		screen_util.fade_in_circular_async(0, 'linear')

		mini_game_manager:StartMiniGame(self.minigame_name)

	elseif main_quest_progress.InnerProgress == 22 then
		change_leader_character({ self.get_sohee(), self.get_count_daughter() })
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif main_quest_progress.InnerProgress == 23 or main_quest_progress.InnerProgress == 24 then
		-- 섹션 7일 때 입장 하면 소히를 파티원으로 추가
		change_leader_character({ self.get_sohee(), self.get_count_daughter() })
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	else
		change_leader_character()
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	end

	-- 태양 이팩트 배치
	self.sun_effect = self.get_sun_effect():Instantiate(vector(0.5, 0, 39))
	self.sun_effect.transform.localRotation = unity_class.quaternion.Euler(90, 0, 0)
end

function local_class:game_done_routine()
	if self.minigame ~= nil then
		mini_game_manager:DisposeMiniGame(self.minigame_name)
	end
	self.minigame = nil

	screen_util.fade_out_circular_async(0, 'linear')

	-- 대략 텀 주고 페이드함
	wait_for_sec(1)

	-- 시작 연출
	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, 'linear')
	coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(get_party_leader().Position,
			get_party_leader().Direction, game_string:GetString(stage.Name)))

	music_player_util.play_stage_music({ state = 'field' })

	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	field_ui_manager:Show()
	party_util.reset_controllers()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
