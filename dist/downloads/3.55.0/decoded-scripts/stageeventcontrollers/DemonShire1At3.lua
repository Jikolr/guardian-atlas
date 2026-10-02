local local_class = newclass('DemonShire1At3Controller')

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

	-- 마법진 이팩트
	self.get_fx_magic_circle = function() return unity_object_pool.GetOrCreate('MagicCircle_AppearIdle') end

	-- 소히 가져오기
	self.get_sohee = function() return get_character('sohee') end

	-- 백작 딸 가져오기
	self.get_count_daughter = function() return get_character('count_daughter') end

	-- 메인 퀘스트 id
	self.main_quest_id = 286

	-- 피라미드 내부 이벤트를 보았는가?
	self.is_show_inside_zone_event = false

	-- 피라미드 내부 이벤트
	self.inside_zone_name = 'inside_zone_auto_event'

	-- 피라미드 내부 이벤트 보았는지 여부 key
	self.inside_zone_event_key = 'pyramid_1_inside_zone_event'

	-- 엘레베이터 이름
	self.elevator_name = 'elevator_inner_'

	-- 엘레베이터 갯수
	self.elevator_count = 2

	--region 마법진 관련

	-- 마법진 위치
	self.magic_circle_pos_list = nil

	-- 마법진이 이동할 위치
	self.target_pos_list = nil

	-- 마법진 이팩트 캐싱
	self.magic_circle_effect_list = nil

	-- 마법진 존 이름
	self.magic_circle_zone_name = 'magic_circle_zone_'

	-- 마법진 도착 방향 리스트
	self.magic_circle_dir_list = nil

	-- 마법진으로 이동중인지?
	self.warping_magic_circle = false

	-- 마법진 갯수
	self.magic_circle_count = 2

	--endregion

end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')

	self.get_fx_magic_circle()
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
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end
	return false
end

function local_class:on_interact_event(e)
	for i = 1, self.elevator_count do
		-- 엘레베이터 텔레포트
		local elevator = get_field_object(self.elevator_name .. i)
		if not self.party_teleporting and lua_helper.reference_equals(e.Target, elevator) then
			sp_util.play_normal_screenplay(self.teleport_party_to_marker, self, self.elevator_name .. i)
			return true
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.inside_zone_name)
			and not self.is_show_inside_zone_event then
		self.is_show_inside_zone_event = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.directing_inside_auto_event, self))
		return true
	end

	-- 마법진 연출
	for i = 1, self.magic_circle_count do
		if type_util.is_zone_full_enter(e, user_party.Leader, self.magic_circle_zone_name .. i)
				and not self.warping_magic_circle then
			self.warping_magic_circle = true
			sp_util.play_normal_screenplay(self.warp_magic_circle, self, i)
			return true
		end
	end

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

--endregion


function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))

	-- 마법진 dispose
	self.magic_circle_effect_list = nil
	self.magic_circle_pos_list = nil
	self.magic_circle_dir_list = nil

	if self.magic_circle_effect_list ~= nil then
		for i = 1, #self.magic_circle_effect_list do
			self.magic_circle_effect_list[i]:Dispose()
		end
		self.magic_circle_effect_list = nil
	end

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

	-- 피라미드 안쪽 구역 이벤트 진행 여부 확인
	self:check_inside_zone(main_quest_progress)

	-- 마법진 세팅
	self:set_magic_circle(main_quest_progress)

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
		start_stage_event('left', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 7 then
		-- 섹션 7일 때 입장 하면 소히를 파티원으로 추가
		change_leader_character({ self.get_sohee(), self.get_count_daughter() })

		-- 세이브 포인트가 있다면 여기서 시작 연출을 하지 않는다.
		local save_point = quest_util.get_custom_state(main_quest_progress, 'save_point_key')
		local is_directing_start = save_point <= 0 or save_point >= 3
		if is_directing_start then
			start_stage_event('left', field:GetMarker('s8_start_pos').position, true, true)
		else
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
			message_system:Publish(CS.Oak.StageStartEvent.Instance)
		end
	else
		--TODO: 나머지 섹션별로 위치 정해줘야 할듯
		change_leader_character()
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	end
end

function local_class:check_inside_zone(quest_progress)
	local custom_state = quest_util.get_custom_state(quest_progress, self.inside_zone_event_key)
	self.is_show_inside_zone_event = custom_state > 0

	if not self.is_show_inside_zone_event then
		-- 이벤트 진행할 3명의 npc Talk 비워둠
		local event_npc_count = 3
		for i = 1, event_npc_count do
			local npc = get_character('pyramid_4_' .. i)
			npc.Interactable.Talk = nil

			if i == 1 then
				character_util.remove_emotion(npc)
			end
		end
	end
end

-- 엘레베이터 텔레포트 이동
function local_class:teleport_party_to_marker(marker_name)
	self.party_teleporting = true
	local marker = field:GetMarker(marker_name)

	music_player_util.play_sfx_one_shot('01_stage_in_teleport_01')

	screen_util.fade_out_circular_async(0.6, 'ease_in_out_sine')

	-- FIXME : 배경이 보이지 않는 다른 구역 사이로 이동하는 경우 다른 곳으로 나갔다 오면 해결되므로 임시로 이렇게 수정
	for i = 0, user_party.Count - 1 do
		character_util.set_position(user_party[i], vector(999, 0, 999))
	end
	coroutine.yield(nil)

	local pos = marker.position
	local direction = marker.direction
	local dir_vector = CS.Oak.DirectionExtensions.ToVector3(direction)
	for i = 0, user_party.Count - 1 do
		character_util.set_position(user_party[i], pos - dir_vector * i)
		character_util.set_direction(user_party[i], direction)
	end

	-- 카메라 그리드 변경 기다림
	coroutine.yield(nil)

	screen_util.fade_in_circular_async(0.6, 'ease_in_out_sine')

	self.party_teleporting = false
end

function local_class:set_magic_circle(quest_progress)
	if quest_progress ~= nil and not quest_progress.IsComplete
			and quest_progress.InnerProgress < 8 then
		-- 9섹션보다 적을 때는 들어가는 마법진만
		self.magic_circle_count = 1
	end

	self.magic_circle_pos_list = {}
	self.target_pos_list = {}
	self.magic_circle_effect_list = {}
	self.magic_circle_dir_list = {}

	local dir_list = { 'down', 'up' }
	for i = 1, self.magic_circle_count do
		local magic_circle_pos = field:GetMarker('magic_circle_point_' .. i).position
		table.insert(self.magic_circle_pos_list, magic_circle_pos)

		local target_circle_pos = field:GetMarker('pyramid_roof_' .. i).position
		table.insert(self.target_pos_list, target_circle_pos)

		local magic_circle_effect = self.get_fx_magic_circle():Instantiate(magic_circle_pos)
		table.insert(self.magic_circle_effect_list, magic_circle_effect)

		table.insert(self.magic_circle_dir_list, dir_list[i])
	end
end

-- 최상층으로 워프하는 이벤트
function local_class:warp_magic_circle(index)
	party_util.align_party(self.magic_circle_pos_list[index] + unity_class.vector3.forward
	, 'down', 1, 'arc')
	coroutine.yield(nil)

	music_player_util.play_sfx_one_shot('02_cast_magic_02')

	for i = 0, user_party.Count - 1 do
		character_util.set_direction(user_party[i], 'down')
		character_util.spine_set_alpha_fade(user_party[i], 0, 0.5)
	end
	wait_for_sec(0.5)

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	-- 파티원들 태양 제어실로
	party_util.align_party(self.target_pos_list[index], self.magic_circle_dir_list[index], 0, 'arc')

	wait_for_sec(0.5)
	for i = 0, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 1, 0.5)
	end

	-- 마법진 이동 CustomStageEvent
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'warp_magic_circle' }))

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.warping_magic_circle = false
end

--region 자동 이벤트

-- 피라미드 내부 자동 이벤트
function local_class:directing_inside_auto_event()
	-- 커스텀 스테이트 저장
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	quest_util.set_custom_state(main_quest_progress, self.inside_zone_event_key, 1)

	local npc_list = {}
	local event_npc_count = 3
	for i = 1, event_npc_count do
		local npc = get_character('pyramid_4_' .. i)
		table.insert(npc_list, npc)
	end

	local string_key = 'ds_pyramid_1_oneline_'

	--택배원(right, idle, idle) : 오늘따라 로얄가드들이 많이 보이는 거 같지 않아?
	speech_bubble_util.show_speech_bubble_async(npc_list[1], { key = string_key .. 12 })

	--택배원(left, tired, idle) : 그런 게 뭐가 중요해… 아직도 남은 일이 산더미인 게 중요하지.
	speech_bubble_util.show_speech_bubble_async(npc_list[2], { key = string_key .. 13 })

	--택배원(right, tired, idle) : 하긴… 난 지금 온몸이 쑤시는 거 같아.
	character_util.set_emotion(npc_list[1], { name = 'tired' })
	speech_bubble_util.show_speech_bubble_async(npc_list[1], { key = string_key .. 14 })

	--택배원(right, tired, idle) : 나도 그래… 빨리 끝내고 쉬고 싶어.
	speech_bubble_util.show_speech_bubble_async(npc_list[3], { key = string_key .. 15 })

	npc_list[1].Interactable.Talk = string_key .. 14
	npc_list[2].Interactable.Talk = string_key .. 13
	npc_list[3].Interactable.Talk = string_key .. 15
end

--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
