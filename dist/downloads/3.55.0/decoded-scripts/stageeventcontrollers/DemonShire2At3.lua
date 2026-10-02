local local_class = newclass('DemonShire2At3Controller')

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

	-- 깜짝 상자 가져오기
	self.get_surprise_box = function() return get_field_object('surprise_box_1') end

	-- 깜짝 상자 터질 때 이팩트
	self.get_fx_explosion = function() return unity_object_pool.GetOrCreate('FX_Explosion_Bomb_new') end

	-- 깜짝 상자 커스텀 키
	self.surprise_box_key = 'open_surprise_box_key'

	-- 깜짝 상자를 열었는가?
	self.is_opened_surprise_box = false

	-- 괴상한 인테리어 프로그레스
	self.strange_interior_progress = 3

	-- 메인 퀘스트 id
	self.main_quest_id = 286

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
	self.magic_circle_count = 3

	--endregion

	-- 하수도 이벤트 존 이름
	self.sewer_zone_name = 'sewer_zone'

	-- bgm 대신 깔릴 sfx
	self.background_sfx = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StarPieceGetEvent), 'on_starpiece_get_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
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

function local_class:on_stage_start_event(e)
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'interacting' and not self.is_opened_surprise_box then
		local surprise_box = self.get_surprise_box()
		if lua_helper.reference_equals(e.Sender, surprise_box) then
			self.is_opened_surprise_box = true
			surprise_box.Interactable = CS.Oak.NonInteractable.Instance
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.bomb_surprise_box
			, self, surprise_box))
			return true
		end
	elseif e:GetParamAt(0) == 'reset_surprise_box' then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.reset_surprise_box, self))
		return true
	elseif e:GetParamAt(0) == 'bgm' then
		if e:GetParamAt(1) == 'play' then
			self:play_sewer_bgm()
		elseif e:GetParamAt(1) == 'stop' then
			local param = e:GetParamAt(2)
			local is_play_bgm = false

			if param then
				if param == 'true' then
					is_play_bgm = true
				end
			end

			self:stop_sewer_bgm(is_play_bgm)
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	-- 마법진 연출
	for i = 1, self.magic_circle_count do
		if type_util.is_zone_full_enter(e, user_party.Leader, self.magic_circle_zone_name .. i)
				and not self.warping_magic_circle then
			self.warping_magic_circle = true
			sp_util.play_normal_screenplay(self.warp_magic_circle, self, i)
			return true
		end
	end

	if type_util.is_zone_full_enter(e, user_party.Leader, 'strange_interior_zone') then
		if self.strange_interior_progress == 0 then
			self.strange_interior_progress = 1
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_strange_interior_zone_1, self))
		elseif self.strange_interior_progress == 2 then
			self.strange_interior_progress = 3
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_strange_interior_zone_2, self))
		end
		return true
	end

	if e.FullEnter then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if e.Zone.Name == self.sewer_zone_name then
				self:play_sewer_bgm()

				return true
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if e.Zone.Name == self.sewer_zone_name then
				self:stop_sewer_bgm(true)

				return true
			end
		end
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, get_field_object('strange_interior_stone_1')) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.appear_strange_interior_switch,
				self, 1))
		return true
	elseif lua_helper.reference_equals(e.FieldObject, get_field_object('strange_interior_stone_2')) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.appear_strange_interior_switch,
				self, 2))
		return true
	end
	return false
end

function local_class:on_starpiece_get_event(e)
	if star_piece_util.has_star_piece('strange_interior_star_piece') then
		if self.strange_interior_progress < 2 then
			self.strange_interior_progress = 2
		end
		return true
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
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StarPieceGetEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
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

	self:stop_sewer_bgm()

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

	-- 마법진 세팅
	self:set_magic_circle(main_quest_progress)

	-- 퀘스트정보가 없거나 클리어 했다면 기본 위치에서 시작
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		change_leader_character()
		start_stage_event('left', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 14 then
		-- 섹션 15일 때 입장 하면 소히, 딸을 파티원으로 추가
		change_leader_character({ self.get_sohee(), self.get_count_daughter() })

		-- 세이브 포인트가 있다면 여기서 시작 연출을 하지 않는다.
		-- 이전 섹션들을 다깨고 왔으면 세이브포인트 키의 값은 2
		local save_point = quest_util.get_custom_state(main_quest_progress, 'save_point_key')
		local is_directing_start = save_point <= 2 or save_point >= 6
		if is_directing_start then
			start_stage_event('right', field:GetMarker('s15_start_pos').position, true, true)
		else
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
			message_system:Publish(CS.Oak.StageStartEvent.Instance)
		end

	elseif main_quest_progress.InnerProgress == 15 then
		-- 섹션 16일 때 입장 하면 소히, 딸을 파티원으로 추가
		change_leader_character({ self.get_sohee(), self.get_count_daughter() })
		start_stage_event('left', field:GetMarker('s16_start_pos').position, true, true)
	else
		change_leader_character()
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	end

	-- 괴상한 인테리어 스테이지 이벤트 세팅
	self:set_strange_interior()
end

function local_class:set_magic_circle(quest_progress)
	if quest_progress ~= nil and not quest_progress.IsComplete
			and quest_progress.InnerProgress < 16 then
		-- 17섹션보다 적을 때는 들어가는 마법진만
		self.magic_circle_count = 1
	end

	self.magic_circle_pos_list = {}
	self.target_pos_list = {}
	self.magic_circle_effect_list = {}
	self.magic_circle_dir_list = {}

	local dir_list = { 'down', 'up', 'down' }
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
	party_util.align_party(self.target_pos_list[index], self.magic_circle_dir_list[index], 0.1, 'arc')

	wait_for_sec(0.5)
	for i = 0, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 1, 0.5)
	end

	-- 마법진 이동 CustomStageEvent
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'warp_magic_circle' }))

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.warping_magic_circle = false
	end

-- 깜짝상자 폭 발
function local_class:bomb_surprise_box(surprise_box)
	-- 서프라이즈 상자 비활성화
	surprise_box.ActiveState = active_state('disabled')

	-- 상자 터짐
	self.get_fx_explosion():Instantiate(surprise_box.Position)

	-- 리더에게 데미지 줌
	local leader = get_party_leader()
	local damage_rate = 0.2

	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Trap
	damage_info.sender = surprise_box
	damage_info.target = leader
	damage_info.damage = math.floor(leader.FieldObjectStatsBehaviour.MaxHP * damage_rate)
	damage_info.notMortal = true
	damage_info.noCritical = true

	command_util.execute_damage(damage_info)

	-- 상자 열었다고 custom state 저장
	self.is_opened_surprise_box = true
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	quest_util.set_custom_state(main_quest_progress, self.surprise_box_key, 1)
end

-- 깜짝 상자 리셋
function local_class:reset_surprise_box()
	self.is_opened_surprise_box = false
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	quest_util.set_custom_state(main_quest_progress, self.surprise_box_key, -1)

	local surprise_box = self.get_surprise_box()
	surprise_box.ActiveState = active_state('enabled')
	surprise_box.Interactable = CS.Oak.Interactable()
end

-- 괴상한 인테리어 세팅
function local_class:set_strange_interior()
	local civil = get_character('strange_interior_civil')
	local carpenter = get_character('strange_interior_carpenter')

	if not star_piece_util.has_star_piece('strange_interior_star_piece') then
		self.strange_interior_progress = 0

		character_util.remove_anim_and_emotion(civil)
		character_util.remove_anim_and_emotion(carpenter)
		civil.Interactable.Talk = ''
		carpenter.Interactable.Talk = ''
	end
end

-- 괴상한 인테리어 존 엔터
function local_class:enter_strange_interior_zone_1()
	local civil = get_character('strange_interior_civil')
	local carpenter = get_character('strange_interior_carpenter')
	local release_time = 0.934
	local attack_time = 0.5

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', parent = civil })
	character_util.set_anim(civil, { name = 'question', loop = false })
	-- 정말 아무도 풀 수 없게 만든 것 맞겠지?
	speech_bubble_util.show_speech_bubble_async(civil, { key = 'strange_interior_1' })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', parent = civil })
	character_util.set_anim_and_emotion(carpenter, {name = 'release', remove_after = release_time,
	                                                sfx_name = '01_swing_01'}, { name = 'smile'})
	-- 그럼요, 제가 방 탈출 설계만 10년입니다.
	speech_bubble_util.show_speech_bubble_async(carpenter, { key = 'strange_interior_2' })

	music_player_util.play_sfx({ sfx_name = '01_swing_01', parent = carpenter })
	character_util.set_direction(carpenter, 'left')
	character_util.set_anim_and_emotion(carpenter, {name = 'attack', remove_after = attack_time},
			{ name = 'attack'})
	-- 이 정도면 사람들 전부 포기하고 나올 걸요?
	speech_bubble_util.show_speech_bubble_async(carpenter, { key = 'strange_interior_3' })
	character_util.set_emotion(carpenter, { name = 'smile' })
	character_util.set_direction(carpenter, 'right')

	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01', parent = civil })
	character_util.set_anim_and_emotion(civil, { name = 'cross_arm', loop = false }, { name = 'doyagao'})
	character_util.set_direction(civil, 'down')
	-- 좋아, 탈출 성공 상품 새로 채워넣을 일은 없겠군!
	speech_bubble_util.show_speech_bubble_async(civil, { key = 'strange_interior_4' })

	carpenter.Interactable.Talk = 'strange_interior_3'
	civil.Interactable.Talk = 'strange_interior_4'

end

function local_class:enter_strange_interior_zone_2()
	local civil = get_character('strange_interior_civil')
	local carpenter = get_character('strange_interior_carpenter')

	civil.Interactable.Talk = ''
	carpenter.Interactable.Talk = ''

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', parent = civil })
	character_util.set_direction(civil, 'left')
	character_util.set_emotion(civil, { name = 'attack' })
	character_util.set_emotion(carpenter, { name = 'tired' })
	-- 어떻게 된 거야? 벌써 탈출해서 상품 챙긴 사람이 나왔잖아!
	speech_bubble_util.show_speech_bubble_async(civil, { key = 'strange_interior_6' })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', parent = civil })
	character_util.set_anim(civil, { name = 'release', sfx_name = '01_swing_01' })
	-- 인테리어 공사비 당장 환불해!
	speech_bubble_util.show_speech_bubble_async(civil, { key = 'strange_interior_7' })

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', parent = carpenter })
	character_util.set_anim(carpenter, { name = 'question', loop = false })
	-- 설계대로면 저게… 절대 열릴 수가 없는데…
	speech_bubble_util.show_speech_bubble_async(carpenter, { key = 'strange_interior_8' })

	civil.Interactable.Talk = 'strange_interior_7'
	carpenter.Interactable.Talk = 'strange_interior_8'
end

function local_class:appear_strange_interior_switch(num)
	local switch = num == 1 and get_field_object('strange_interior_switch_1')
			or get_field_object('strange_interior_switch_2')
	local pos = num == 1 and get_field_object('strange_interior_stone_1').Position
			or get_field_object('strange_interior_stone_2').Position
	switch.Position = pos
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

--region bgm
function local_class:play_sewer_bgm()
	music_player_util.play_stage_music({ state = 'muted' })
	music_player_util.remove_stage_music_clip({ state = 'field' })

	self:stop_sewer_bgm()

	self.background_sfx = music_player_util.play_sfx({ sfx_name = '01_amb_cave_01', loop = true,
													   type_priority = 'loop',
													   player_priority = 'default' })
end

function local_class:stop_sewer_bgm(is_play_bgm)
	if is_play_bgm then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			music_player_util.set_stage_music_clip_async({
				name = 'ondemand/v2_39_demonshire/audio:bgm_demonshire_main', state = 'field'
			})
			music_player_util.play_stage_music({ state = 'field' })
		end))
	end

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
