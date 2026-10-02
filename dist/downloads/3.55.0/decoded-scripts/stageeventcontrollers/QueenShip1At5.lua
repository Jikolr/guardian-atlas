local local_class = newclass('QueenShip1At5Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 메인 퀘스트 id
	self.main_quest_id = 311

	-- 파이몬
	self.get_pymon = function() return get_character('pymon') end

	-- 안드라스
	self.get_andras = function() return get_character('andras') end

	-- 꼬마 공주
	self.get_little_princess = function() return get_character('little_princess') end

	-- 반짝이 이팩트
	self.get_twinkle_effect = function() return unity_object_pool.GetOrCreate('FX_Object_Twinkle') end

	-- 캐싱한 반짝이 이팩트 리스트
	self.twinkle_effect_list = {}
end

function local_class:load_resource()
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:on_event(e)
	return false
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

function local_class:pre_setting()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 메인 캐릭터를 기사로 교체하는 함수
	local change_leader_character = function(party_member)
		-- 기사를 리더로
		local leader = user_util.get_knight_character('knight_female', 'knight_male')
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

	self.get_twinkle_effect()

	message_system:Publish(CS.Oak.BattleGateOpenEvent.Create('s21_s2_battle_gate_1', false))

	change_leader_character({ self.get_little_princess() })
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 16 then
		start_stage_event('right', field:GetMarker('s21_start').position, false, false)
	elseif main_quest_progress.InnerProgress == 17 then
		start_stage_event('right', field:GetMarker('s18_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 18 then
		start_stage_event('right', field:GetMarker('s19_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 19 then
		start_stage_event('right', field:GetMarker('s20_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 20 then
		start_stage_event('left', field:GetMarker('s21_start').position, true, true)
	else
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	end
end

function local_class:on_stage_start_event(e)
	-- 반짝이 이팩트 달 부술 수 있는 장애물 id List
	local twinkle_effect_index_list = { 1, 2, 13, 14, 15, 16 }

	-- 부수는 오브젝트 top Hp Bar 안뜨도록 무시 처리
	local obstacle_count = 16
	for i = 1, obstacle_count do
		local obstacle = get_field_object('s21_s2_1_obstacle_' .. i)
		if table_util.contain_value(twinkle_effect_index_list, i) then
			-- 이팩트 세팅
			local twinkle_effect = self.get_twinkle_effect():Instantiate(obstacle.Position + vector(0, 0.5, 0),
					unity_class.quaternion.identity, obstacle.Transform)
			table.insert(self.twinkle_effect_list, twinkle_effect)
		end

		message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(obstacle, true))
	end

	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	if self.twinkle_effect_list ~= nil then
		for i = 1, #self.twinkle_effect_list do
			if self.twinkle_effect_list[i] ~= nil then
				self.twinkle_effect_list[i]:Dispose()
				self.twinkle_effect_list[i] = nil
			end
		end

		self.twinkle_effect_list = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
