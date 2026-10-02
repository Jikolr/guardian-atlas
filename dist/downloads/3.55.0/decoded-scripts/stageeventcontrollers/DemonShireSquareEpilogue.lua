local local_class = newclass('DemonShireSquareEpilogueController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 이벤트 존 이름
	self.event_npc_zone_name = 'event_npc_zone_'

	-- 아이템 스펙 이름
	self.balloon_item_spec_name = 'ds_balloon'
	self.commemorative_plaque_item_spec_name = 'ds_commemorative_plaque'

	-- 후일담 이벤트 npc
	self.get_event_npc = function(event_num, npc_num)
		return get_character(string.format('event_npc_%d_%d', event_num, npc_num))
	end

	-- 후일담 이벤트를 봤는가 여부
	self.event_npc_trigger_enum = {
		none = 1 << 0,
		event_1 = 1 << 1,
		event_2_1 = 1 << 2,
		event_2_2 = 1 << 3,
		event_4 = 1 << 4,
		event_5 = 1 << 5,
		event_6 = 1 << 6,
		event_7 = 1 << 7,
		event_8 = 1 << 8,
		event_9 = 1 << 9,
		event_10 = 1 << 10,
		event_11 = 1 << 11
	}
	self.current_event_npc_trigger = self.event_npc_trigger_enum.none

	-- 후일담 이벤트 선행 퀘스트 리스트
	self.event_npc_quest_list = {
		event_3 = 287,
		event_4 = 305,
		event_5 = 293,
		event_7 = 294,
		event_8 = 296,
		event_9 = 289
	}

	-- 후일담 이벤트 선행 퀘스트를 완료하여, 이벤트를 볼 수 있는가 여부
	self.is_complete_event_npc_quest_list = {
		event_3 = false,
		event_4 = false,
		event_5 = false,
		event_7 = false,
		event_8 = false,
		event_9 = false
	}

	-- coroutine req id list
	self.req_id_list = {}

	self.main_quest_id = 286
	self.main_quest_progress = -1
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')

	self:dispose_req_id()

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	if user_progress:GetStartedQuest(self.main_quest_id) ~= nil then
		self.main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id).InnerProgress
	end
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	self:stage_start_setting()

	return true
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			-- 1번 이벤트
			if self.current_event_npc_trigger & self.event_npc_trigger_enum.event_1 == 0 and
				e.Zone.Name == self.event_npc_zone_name .. 1 then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_1_zone_balloon, self))
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_1_zone_kid, self))
				return true
				-- 2번 이벤트
			elseif self.current_event_npc_trigger & self.event_npc_trigger_enum.event_2_1 == 0 and
				e.Zone.Name == self.event_npc_zone_name .. string.format('%d_%d', 2, 1) then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_2_zone_1, self))
				return true
			elseif self.current_event_npc_trigger & self.event_npc_trigger_enum.event_2_2 == 0 and
				e.Zone.Name == self.event_npc_zone_name .. string.format('%d_%d', 2, 2) then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_2_zone_2, self))
				return true
				-- 3번 이벤트
			elseif self.is_complete_event_npc_quest_list.event_3 and e.Zone.Name == self.event_npc_zone_name .. 3 then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_3_zone, self))
				return true
				-- 4번 이벤트
			elseif self.is_complete_event_npc_quest_list.event_4 and
				self.current_event_npc_trigger & self.event_npc_trigger_enum.event_4 == 0 and
				e.Zone.Name == self.event_npc_zone_name .. 4 then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_4_zone, self))
				return true
				-- 5번 이벤트
			elseif self.is_complete_event_npc_quest_list.event_5 and
				self.current_event_npc_trigger & self.event_npc_trigger_enum.event_5 == 0 and
				e.Zone.Name == self.event_npc_zone_name .. 5 then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_5_zone, self))
				return true
				-- 6번 이벤트
			elseif self.current_event_npc_trigger & self.event_npc_trigger_enum.event_6 == 0 and
				e.Zone.Name == self.event_npc_zone_name .. 6 then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_6_zone, self))
				return true
				-- 7번 이벤트
			elseif self.is_complete_event_npc_quest_list.event_7 and
				self.current_event_npc_trigger & self.event_npc_trigger_enum.event_7 == 0 and
				e.Zone.Name == self.event_npc_zone_name .. 7 then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_7_zone, self))
				return true
				-- 8번 이벤트
			elseif self.is_complete_event_npc_quest_list.event_8 and
				self.current_event_npc_trigger & self.event_npc_trigger_enum.event_8 == 0 and
				e.Zone.Name == self.event_npc_zone_name .. 8 then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_8_zone, self))
				return true
				-- 9번 이벤트
			elseif self.is_complete_event_npc_quest_list.event_9 and
				self.current_event_npc_trigger & self.event_npc_trigger_enum.event_9 == 0 and
				e.Zone.Name == self.event_npc_zone_name .. 9 then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_9_zone, self))
				return true
				-- 10번 이벤트
			elseif self.current_event_npc_trigger & self.event_npc_trigger_enum.event_10 == 0 and
				e.Zone.Name == self.event_npc_zone_name .. 10 then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_10_zone, self))
				return true
				-- 11번 이벤트
			elseif self.current_event_npc_trigger & self.event_npc_trigger_enum.event_11 == 0 and
				e.Zone.Name == self.event_npc_zone_name .. 11 then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.enter_event_npc_11_zone, self))
				return true
			end
		end
	end

	return false
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == self.main_quest_id then
		self.main_quest_progress = e.CurrentProgress
	end

	return true
end

--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

--region setting
function local_class:stage_start_setting()
	-- 특정 후일담 이벤트를 진행할 수 있는지, 선행 퀘스트 클리어 여부 체크
	for event_name, quest_id in pairs(self.event_npc_quest_list) do
		local quest_progress = user_progress:GetStartedQuest(quest_id)

		if quest_progress ~= nil and quest_progress.IsComplete then
			self.is_complete_event_npc_quest_list[event_name] = true
		end
	end

	-- 이벤트 1 초기 설정
	-- 풍선든 남자 풍선 세팅
	local balloon_man = self.get_event_npc(1, 1)

	local item_data = game_data_service.GetData('ItemData')
	local balloon_item_id = item_data:GetSpec(self.balloon_item_spec_name).Id
	local balloon_item = drop_item_util.create_item({
		pos = balloon_man.Position + vector(-0.25, 0.2, 0.3), itemid = balloon_item_id, notforinven = true,
		lootstate = 'dontfindlooter', sprscale = 0.75, showoncharacter = true
	})

	local kid_1 = self.get_event_npc(1, 2)
	local kid_2 = self.get_event_npc(1, 3)
	character_util.remove_anim(kid_1)
	character_util.remove_anim(kid_2)
	character_util.set_anim(kid_1, { name = 'success', sfx_name = '01_small_jump_01' })
	character_util.set_anim(kid_2, { name = 'success', sfx_name = '01_small_jump_01' })

	-- 달리는 꼬마들 세팅
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.balloon_kid_run, self))

	-- 이벤트 3 초기 설정
	if self.is_complete_event_npc_quest_list.event_3 then
		-- 초록색 원 3번 맨드레이크 - ds_mandrake, growth 상태로 1.5배 확대하여 배치
		local mandrake = self.get_event_npc(3, 2)
		character_util.set_scale_factor(mandrake, 'growth', 1.5)
		character_util.remove_anim(mandrake)
		character_util.set_anim(mandrake, { name = 'success', sfx_name = '01_player_jump_01' })
	end

	-- 이벤트 4 초기 설정
	if self.is_complete_event_npc_quest_list.event_4 then
		-- 리리스 피규어 노란색 틴트 설정
		local demon_ceo = self.get_event_npc(4, 5)

		demon_ceo.SpineController:AddColor('figure', unity_color({ 0.2, 0.2, 0.2, 1 }), 1, 0)

		demon_ceo.SpineController:AddFadeColor('figure', CS.UnityEngine.Color(0.9375, 0.81640625, 0.34375, 1), 0.4, 0)
		demon_ceo.SpineController:AddColor('figure', CS.UnityEngine.Color(0.9375, 0.81640625, 0.34375, 1), 1, 0)
		character_util.set_scale_factor(demon_ceo, 'figure', 0.5)
		character_util.set_anim(demon_ceo, { name = 'jingak', loop = false })
		field_ui_manager:RemoveUI(demon_ceo, CS.Oak.FieldUiType.CharacterStats)
	end

	-- 이벤트 5 초기 설정
	if self.is_complete_event_npc_quest_list.event_5 then
		-- 패잔병 copper_pannel 스프라이트 손에 쥔 채 right, smile, bow_idle 상태.
		local loser = self.get_event_npc(5, 1)

		local item_id = item_data:GetSpec(self.commemorative_plaque_item_spec_name).Id
		local item = drop_item_util.create_item({
			pos = loser.Position, itemid = item_id, notforinven = true, lootstate = 'dontfindlooter', sprscale = 0.7
		})
		local bone_follower = item.SpriteTransform.parent.gameObject:AddComponent(typeof(CS.Spine.Unity.BoneFollower))

		bone_follower.followBoneRotation = false
		bone_follower.SkeletonRenderer = loser.SpineController.SkeletonAnimation
		bone_follower:SetBone('[base]weapon1_side')
	end

	-- 이벤트 7 초기 설정
	if self.is_complete_event_npc_quest_list.event_7 then
		local quest_progress = user_progress:GetStartedQuest(self.event_npc_quest_list.event_7)
		local grade = quest_progress.Grade

		if grade ~= 1 then
			local chef = self.get_event_npc(7, 1)
			local mouse = self.get_event_npc(7, 2)

			character_util.set_emotion(chef, { name = 'tired' })
			character_util.set_active_state(mouse, 'disabled')
		else
			local mouse = self.get_event_npc(7, 2)
			character_util.set_scale_factor(mouse, 'mouse', 0.5)
		end
	end

end

-- 풍선을 들고 달리는 꼬마
function local_class:balloon_kid_run()
	local balloon_kid = self.get_event_npc(1, 4)
	local kid = self.get_event_npc(1, 5)

	local item_data = game_data_service.GetData('ItemData')
	local balloon_item_id = item_data:GetSpec(self.balloon_item_spec_name).Id
	local balloon_item = drop_item_util.create_item({
		pos = balloon_kid.Position, itemid = balloon_item_id, notforinven = true, lootstate = 'dontfindlooter',
		sprscale = 0.75, showoncharacter = true
	})

	local balloon_offset_list = {
		down = vector(-0.25, 0, 0.5),
		right = vector(0.25, 0, 0.5),
		up = vector(0.25, 0, 0.5),
		left = vector(-0.25, 0, 0.5)
	}

	-- 3번 꼬마, 4번 꼬마 동선대로 빙글빙글 돌고 있다.
	-- 충돌 판정 없음

	balloon_kid.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
	kid.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance

	music_player_util.play_sfx({play_pos = balloon_kid.Position,
								sfx_name = '01_dash_01', loop = true, max_distance = 4})

	local speed = 4
	local see_event_progress = 31

	while true do
		if self.main_quest_progress >= see_event_progress then
			-- 아래로 이동 할 때
			balloon_item.Position = balloon_kid.Position + balloon_offset_list.down
			character_util.move_waypoint(kid, kid.Position + vector(0, 0, 2), speed, true)
			character_util.move_waypoint(balloon_kid, balloon_kid.Position + vector(0, 0, -2),
					speed, true)
			drop_item_util.move_to_async(balloon_item, balloon_item.Position + vector(0, 0, -2),
					nil, speed)

			-- 오른쪽으로 이동 할 때
			balloon_item.Position = balloon_kid.Position + balloon_offset_list.right
			character_util.move_waypoint(kid, kid.Position + vector(-2, 0, 0), speed, true)
			character_util.move_waypoint(balloon_kid, balloon_kid.Position + vector(2, 0, 0),
					speed, true)
			drop_item_util.move_to_async(balloon_item, balloon_item.Position + vector(2, 0, 0),
					nil, speed)

			-- 위로 이동 할 때
			balloon_item.Position = balloon_kid.Position + balloon_offset_list.up
			character_util.move_waypoint(kid, kid.Position + vector(0, 0, -2), speed, true)
			character_util.move_waypoint(balloon_kid, balloon_kid.Position + vector(0, 0, 2),
					speed, true)
			drop_item_util.move_to_async(balloon_item, balloon_item.Position + vector(0, 0, 2),
					nil, speed)

			-- 왼쪽으로 이동 할 때
			balloon_item.Position = balloon_kid.Position + balloon_offset_list.left
			character_util.move_waypoint(kid, kid.Position + vector(2, 0, 0), speed, true)
			character_util.move_waypoint(balloon_kid, balloon_kid.Position + vector(-2, 0, 0),
					speed, true)
			drop_item_util.move_to_async(balloon_item, balloon_item.Position + vector(-2, 0, 0),
					nil, speed)
		else
			coroutine.yield(nil)
		end
	end
end
--endregion

--region event_1
-- 1번 이벤트 / 삐에로와 풍선 가진 꼬마들
function local_class:enter_event_npc_1_zone_balloon()
	local balloon_man = self.get_event_npc(1, 1)
	local kid_1 = self.get_event_npc(1, 2)
	local kid_2 = self.get_event_npc(1, 3)

	self.current_event_npc_trigger = self.current_event_npc_trigger | self.event_npc_trigger_enum.event_1

	-- 풍선 아저씨 (right, idle, idle) : 이거 받고 즐거운 하루 보내렴.
	speech_bubble_util.show_speech_bubble_async(balloon_man, { key = 'ds_4_at_3_event_1_1' })

	-- 손에 풍선 들고 있음 (mall_balloon)
	-- 1번 꼬마 (left, awesome, success) : 언제나 감사합니다!
	music_player_util.play_sfx_one_shot('01_camera_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(kid_1, { key = 'ds_4_at_3_event_1_2' })

	-- 2번 꼬마 (up, success) : 저도요! 저도 주세요!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	speech_bubble_util.show_speech_bubble_async(kid_2, { key = 'ds_4_at_3_event_1_3' })

	-- 풍선 아저씨와 1, 2번 꼬마는 이벤트 종료 후 원라인 전환.
	balloon_man.Interactable.Talk = 'ds_4_at_3_event_1_1'
	kid_1.Interactable.Talk = 'ds_4_at_3_event_1_2'
	kid_2.Interactable.Talk = 'ds_4_at_3_event_1_2'
end

function local_class:enter_event_npc_1_zone_kid()
	local kid_3 = self.get_event_npc(1, 4)
	local kid_4 = self.get_event_npc(1, 5)

	-- 3번 꼬마는 오른손에 풍선 들고 있음 (mall_balloon)
	-- 트리거 존 입장 시 대사 출력
	-- 빨강4(cry) : 왜 만날 내 풍선 가져가는데!
	music_player_util.play_sfx_one_shot('01_female_cry_02')
	speech_bubble_util.show_speech_bubble_async(kid_4, { key = 'ds_4_at_3_event_1_4' })

	-- 빨강3(smile) : 그야 빙글빙글 도는 게 좋으니까!
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	speech_bubble_util.show_speech_bubble_async(kid_3, { key = 'ds_4_at_3_event_1_5' })

	-- 3, 4번 꼬마는 이후 대사 하지 않음.
end
--endregion

--region event_2
-- 2번 이벤트 / 간수와 죄수들 1
function local_class:enter_event_npc_2_zone_1()
	local prison_officer = self.get_event_npc(2, 2)
	local prisoner = self.get_event_npc(2, 4)

	self.current_event_npc_trigger = self.current_event_npc_trigger | self.event_npc_trigger_enum.event_2_1

	-- 1번 빨간 사각형 존 엔터 시 트리거 이벤트 (컨트롤 빼앗지 않음)
	-- 뱀파이어 간수 (up, idle, idle) : 지역 주민에게 봉사하는 차원에서 복구 작업을 지원한다.
	music_player_util.play_sfx_one_shot('01_male_shout_01')
	speech_bubble_util.show_speech_bubble_async(prison_officer, { key = 'ds_4_at_3_event_2_1' })

	-- 뱀파이어 간수 (up, idle, idle) : 작업에 성실히 임하는 수감자는 포상이 주어질 것이다!
	speech_bubble_util.show_speech_bubble_async(prison_officer, { key = 'ds_4_at_3_event_2_2' })

	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	-- 좌측 중간의 죄수 (down, attack, attack x 2) : 시원한 맥주! 블루스 음악!
	character_util.set_direction(prisoner, 'down')
	character_util.set_emotion(prisoner, { name = 'attack' })
	character_util.set_animation_n_times(prisoner, { name = 'attack', count = 2, sfx = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(prisoner, { key = 'ds_4_at_3_event_2_3' })

	-- 이후 뱀파이어 간수 첫번째 대사와 죄수의 대사 원라인으로 전환.
	prison_officer.Interactable.Talk = 'ds_4_at_3_event_2_1'
	prisoner.Interactable.Talk = 'ds_4_at_3_event_2_3'
end

-- 2번 이벤트 / 간수와 죄수들 2
function local_class:enter_event_npc_2_zone_2()
	local prison_officer = self.get_event_npc(2, 1)

	self.current_event_npc_trigger = self.current_event_npc_trigger | self.event_npc_trigger_enum.event_2_2

	-- 2번 빨간 사각형 존 엔터 시 트리거 이벤트 (컨트롤 빼앗지 않음)
	-- 마족 간수 (down, idle, idle) : 어려움에 처한 주민들을 돕는 일이다.
	speech_bubble_util.show_speech_bubble_async(prison_officer, { key = 'ds_4_at_3_event_2_4' })

	-- 마족 간수 (down, idle, attack) : 특별 사면 대상이 될 수도 있다는 걸 잊지 말도록!
	character_util.set_anim(prison_officer, { name = 'attack', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(prison_officer, { key = 'ds_4_at_3_event_2_5' })

	-- 이후 마족 간수 두번째 대사 원라인으로 전환.
	character_util.remove_anim(prison_officer)
	prison_officer.Interactable.Talk = 'ds_4_at_3_event_2_5'
end
--endregion

--region event_3
-- 3번 이벤트 / 맨드레이크 - 맨드레이크 메이커(287) 퀘스트 클리어 시에만 존재함.
function local_class:enter_event_npc_3_zone()
	local func_name = 'enter_event_npc_3_zone'
	local req_id = self:get_new_req_id(func_name)

	local mandrake_1 = self.get_event_npc(3, 3)
	local mandrake_2 = self.get_event_npc(3, 4)
	local mandrake_3 = self.get_event_npc(3, 2)
	local mandrake_4 = self.get_event_npc(3, 5)

	-- 1번 맨드레이크 (right, smile, idle) : 맨드! 맨드! (트리거 밟는 즉시 대사)
	-- 4번 맨드레이크 (up, idle): 맨드! 맨드! (트리거 밟는 즉시 대사)
	speech_bubble_util.show_speech_bubble(mandrake_1, { key = 'ds_4_at_3_event_3_1' })
	speech_bubble_util.show_speech_bubble(mandrake_4, { key = 'ds_4_at_3_event_3_3' })
	wait_for_sec(0.3)

	if req_id ~= self:get_req_id(func_name) then
		return
	end

	-- 2번 맨드레이크 (right, smile, idle) : 맨드! 맨드! (트리거 밟고 0.3 초 후 대사)
	speech_bubble_util.show_speech_bubble(mandrake_2, { key = 'ds_4_at_3_event_3_2' })
	wait_for_sec(0.2)

	if req_id ~= self:get_req_id(func_name) then
		return
	end

	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	music_player_util.play_sfx_one_shot('01_creature_05')
	-- 3번 맨드레이크 (right, growth, success) : 보고 싶었어! 덕분에 무럭무럭 잘 자라고 있어! (트리거 밟은 후 0.5초 후 대사)
	speech_bubble_util.show_speech_bubble_async(mandrake_3, { key = 'ds_4_at_3_event_3_4' })

	-- 이 이벤트는 존 엔터 할 때마다 반복.
end
--endregion

--region event_4
-- 4번 이벤트 / 듀얼리스트 - 가챠 머신(305) 퀘스트 클리어 시에만 존재함.
function local_class:enter_event_npc_4_zone()
	local demon_kid = self.get_event_npc(4, 1)
	local demon_female = self.get_event_npc(4, 2)
	local demon_male = self.get_event_npc(4, 3)
	local vampire_female = self.get_event_npc(4, 4)

	self.current_event_npc_trigger = self.current_event_npc_trigger | self.event_npc_trigger_enum.event_4

	-- 빨간 사각형 존 엔터 시 트리거 이벤트 (컨트롤 빼앗지 않음)
	-- 마족 꼬마 (right,attack, attack x 2) : 미래 마황 리리스를 제물로 삼고 턴을 종료헌닷!
	music_player_util.play_sfx_one_shot('01_kid_boy_shout_01')
	character_util.set_animation_n_times(demon_kid, { name = 'attack', count = 2, sfx = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(demon_kid, { key = 'ds_4_at_3_event_4_1' })

	-- 마족 여성 (left,surprise,idle) : 헛, 미래가… 모습을 바꿨어?!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	speech_bubble_util.show_speech_bubble_async(demon_female, { key = 'ds_4_at_3_event_4_2' })

	-- 마족 남성 (down, smile, idle) : 네, 네 녀석들… 정말 멋진 승부다!
	music_player_util.play_sfx_one_shot('03_dialogue_china_01')
	speech_bubble_util.show_speech_bubble_async(demon_male, { key = 'ds_4_at_3_event_4_3' })

	-- 뱀파이어 여성 (left,damaged,idle) : 젠장, 얼마나 진심인 거냐고!
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	speech_bubble_util.show_speech_bubble_async(vampire_female, { key = 'ds_4_at_3_event_4_4' })

	-- 이벤트 후 모든 대사 각 NPC 의 원라인으로 전환.
	demon_kid.Interactable.Talk = 'ds_4_at_3_event_4_1'
	demon_female.Interactable.Talk = 'ds_4_at_3_event_4_2'
	demon_male.Interactable.Talk = 'ds_4_at_3_event_4_3'
	vampire_female.Interactable.Talk = 'ds_4_at_3_event_4_4'
end
--endregion

--region event_5
-- 5번 이벤트 / 패잔병 - 시간을 잊은 남자(293) 퀘스트 클리어 시에만 존재함
function local_class:enter_event_npc_5_zone()
	local loser = self.get_event_npc(5, 1)

	self.current_event_npc_trigger = self.current_event_npc_trigger | self.event_npc_trigger_enum.event_5

	-- 패잔병 copper_pannel 스프라이트 손에 쥔 채 right, smile, bow_idle 상태.
	-- 빨간 사각형 존 엔터 시 트리거 이벤트 (컨트롤 빼앗지 않음)
	-- 패잔병 (right, smile, bow_idle) : 이 광경이 보이나…?
	music_player_util.play_sfx_one_shot('01_rustle_01')
	speech_bubble_util.show_speech_bubble_async(loser, { key = 'ds_4_at_3_event_5_1' })

	-- 이후 left, right, up 각 0.7초씩 번갈아본 후 다시 left
	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(loser, 'left')
	wait_for_sec(0.7)

	character_util.set_direction(loser, 'right')
	music_player_util.play_sfx_one_shot('01_swing_01')
	wait_for_sec(0.7)

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(loser, 'up')
	wait_for_sec(0.7)

	-- 패잔병 (right, smile, bow_idle) : 마족과 뱀파이어들이 함께 어울려서 살아가는 세상이라네.
	character_util.set_direction(loser, 'right')
	speech_bubble_util.show_speech_bubble_async(loser, { key = 'ds_4_at_3_event_5_2' })

	music_player_util.play_sfx_one_shot('01_rustle_01')
	-- 패잔병 (right, smile, nod x 2)
	character_util.set_animation_n_times_async(loser, { name = 'nod', count = 2 })

	-- 패잔병 (right, smile, bow_idle) : 우리들의 싸움은…
	character_util.set_anim(loser, { name = 'bow_idle' })
	speech_bubble_util.show_speech_bubble_async(loser, { key = 'ds_4_at_3_event_5_3' })

	-- 패잔병 (right, smile, idle) : 아니 자네들의 희생은…
	character_util.remove_anim(loser)
	speech_bubble_util.show_speech_bubble_async(loser, { key = 'ds_4_at_3_event_5_4' })

	music_player_util.play_sfx_one_shot('01_lights_01')
	-- 패잔병 (right, smile, idle) : 결코 헛되지 않았던 것이네.
	speech_bubble_util.show_speech_bubble_async(loser, { key = 'ds_4_at_3_event_5_5' })

	-- 이후 up 상태로 전환. 인터랙트 시 원라인 대사 출력.
	-- 패잔병 : 자네들의 희생은 결코 헛되지 않았던 것이네.
	loser.Interactable.Talk = 'ds_4_at_3_event_5_5'
end
--endregion

--region event_6
-- 6번 이벤트 / 광장에 나온 연구원들
function local_class:enter_event_npc_6_zone()
	local researcher_1 = self.get_event_npc(6, 1)
	local researcher_2 = self.get_event_npc(6, 2)
	local researcher_3 = self.get_event_npc(6, 3)

	self.current_event_npc_trigger = self.current_event_npc_trigger | self.event_npc_trigger_enum.event_6

	-- 중앙 연구원 left, right, up 각 1초씩 둘러본 후 down 상태로,
	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(researcher_1, 'left')
	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(researcher_1, 'right')
	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(researcher_1, 'up')
	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	-- 중앙 연구원 (up, cast2) : 얘들아, 나 대학원 들어간 이후로 인공태양빛을 처음 쬐는 것 같아!
	character_util.set_direction(researcher_1, 'down')
	speech_bubble_util.show_speech_bubble_async(researcher_1, { key = 'ds_4_at_3_event_6_1' })

	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
	-- 좌측 연구원 (right, cry, cast) : 제발 연구소 보수 공사가 늦게 끝났으면 좋겠다…!
	speech_bubble_util.show_speech_bubble_async(researcher_2, { key = 'ds_4_at_3_event_6_2' })

	music_player_util.play_sfx_one_shot('03_runaway_01')
	-- 우측 연구원 (left, scared, idle - 캐릭터 진동) : 어어… 어떡하지? 아까부터 자꾸 교수님한테 전화가 오거든…?
	character_util.shake(researcher_3, 0.04, 1)
	speech_bubble_util.show_speech_bubble_async(researcher_3, { key = 'ds_4_at_3_event_6_3' })

	-- 이후 각자 대사 원라인으로 전환.
	researcher_1.Interactable.Talk = 'ds_4_at_3_event_6_1'
	researcher_2.Interactable.Talk = 'ds_4_at_3_event_6_2'
	researcher_3.Interactable.Talk = 'ds_4_at_3_event_6_3'
end
--endregion

--region event_7
-- 7번 이벤트 / 누구든지 요리할 수 있다(294) 퀘스트 클리어 시에만 존재함
function local_class:enter_event_npc_7_zone()
	local chef =  self.get_event_npc(7, 1)
	local mouse = self.get_event_npc(7, 2)

	self.current_event_npc_trigger = self.current_event_npc_trigger | self.event_npc_trigger_enum.event_7

	-- 특정 후일담 이벤트를 진행할 수 있는지, 선행 퀘스트 클리어 여부 체크
	for event_name, quest_id in pairs(self.event_npc_quest_list) do
		local quest_progress = user_progress:GetStartedQuest(quest_id)

		if quest_progress ~= nil and quest_progress.IsComplete then
			self.is_complete_event_npc_quest_list[event_name] = true
		end
	end

	-- 퀘스트 클리어 결과에 따라 내용 달라짐.
	local quest_progress = user_progress:GetStartedQuest(self.event_npc_quest_list.event_7)
	local grade = quest_progress.Grade

	if grade == 1 then
		-- 주방에서 쫓겨 났을 때
		-- 주방 보조 (left, smile, release x 2) : 좋은 소식이야, 친구!
		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		character_util.set_animation_n_times(chef, { name = 'release', count = 2, sfx = '01_swing_01' })
		speech_bubble_util.show_speech_bubble_async(chef, { key = 'ds_4_at_3_event_7_1' })

		-- 주방 보조 (left, smile, idle) : 식당이 망한 덕분에 아주 헐값에 가게를 인수하게 됐어!
		speech_bubble_util.show_speech_bubble_async(chef, { key = 'ds_4_at_3_event_7_2' })

		-- 주방 보조 (left, awesome, cast2) : 드디어 우리 가게가 생기는 거야!
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		character_util.set_emotion(chef, { name = 'awesome' })
		character_util.set_anim(chef, { name = 'cast2' })
		speech_bubble_util.show_speech_bubble_async(chef, { key = 'ds_4_at_3_event_7_3' })

		music_player_util.play_sfx_one_shot('01_mouse_01')
		-- 쥐 (right, smile, jump x 3)
		for i = 1, 3 do
			character_util.normal_jump_async(mouse, true)
		end

		-- 이후 ‘드디어 우리 가게가 생기는 거야!’ 원라인 전환.
		chef.Interactable.Talk = 'ds_4_at_3_event_7_3'
	else
		-- 계속 근무 중일 때 (쥐 나오지 않음)
		-- 주방 보조 (left, tired, idle) : 또 어디로 숨은 거야, 친구!
		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
		speech_bubble_util.show_speech_bubble_async(chef, { key = 'ds_4_at_3_event_7_4' })

		-- Right, left, up, down, 0.5씩 둘러보고,
		music_player_util.play_sfx_one_shot('01_swing_01')
		character_util.set_direction(chef, 'right')
		wait_for_sec(0.5)

		music_player_util.play_sfx_one_shot('01_swing_01')
		character_util.set_direction(chef, 'up')
		wait_for_sec(0.5)

		music_player_util.play_sfx_one_shot('01_swing_01')
		character_util.set_direction(chef, 'down')
		wait_for_sec(0.5)

		-- 주방 보조 (left, attack, release) : 친구? 오늘 중요한 날이란 말이야!
		music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
		character_util.set_direction(chef, 'left')
		speech_bubble_util.show_speech_bubble_async(chef, { key = 'ds_4_at_3_event_7_5' })

		-- 이후 ‘또 어디로 숨은 거야, 친구!’ 원라인 전환.
		chef.Interactable.Talk = 'ds_4_at_3_event_7_4'
	end
end
--endregion

--region event_8
-- 8번 이벤트 / 세 가지 시련(296) 퀘스트 클리어 시에만 존재함.
function local_class:enter_event_npc_8_zone()
	local treasure_hunter = self.get_event_npc(8, 1)
	local royal_guard_1 = self.get_event_npc(8, 2)
	local royal_guard_2 = self.get_event_npc(8, 3)

	self.current_event_npc_trigger = self.current_event_npc_trigger | self.event_npc_trigger_enum.event_8

	-- 로얄가드 두 명이 양쪽에서 인디아나 존스를 에워싸고 있다.
	-- 인디아나 존스 (left, attack, idle) : 이봐, 난 전문 트레저 헌터야!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	speech_bubble_util.show_speech_bubble_async(treasure_hunter, { key = 'ds_4_at_3_event_8_1' })

	-- 인디아나 존스 (right, attack, release x 2) : 조금만 파들어가면 분명 보물이 나올 거라니까?
	character_util.set_direction(treasure_hunter, 'right')
	character_util.set_animation_n_times(treasure_hunter, { name = 'release', count = 2, sfx = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(treasure_hunter, { key = 'ds_4_at_3_event_8_2' })

	-- 인디아나 존스 (left, attack, cast2) : 바로 얼마 전에도 어떤 헤실헤실한 친구랑 기가 막힌 모험을…
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	character_util.set_anim(treasure_hunter, { name = 'cast2' })
	speech_bubble_util.show_speech_bubble_async(treasure_hunter, { key = 'ds_4_at_3_event_8_3' })

	-- 우측 로얄가드 (left, attack, dualgun_idle) : 정신차리세요, 은행 벽을 뚫고 있었잖아요!
	music_player_util.play_sfx_one_shot('03_dialogue_angry_01')
	speech_bubble_util.show_speech_bubble_async(royal_guard_1, { key = 'ds_4_at_3_event_8_4' })

	-- 좌측 로얄가드 (right, attack, attack x 1) : 한 번만 더 그러면 그땐 정말 구속입니다!
	music_player_util.play_sfx_one_shot('01_equip_weapon_01')
	music_player_util.play_sfx_one_shot('01_male_shout_01')
	character_util.set_animation_n_times(royal_guard_2, { name = 'attack', sfx = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(royal_guard_2, { key = 'ds_4_at_3_event_8_5' })

	treasure_hunter.Interactable.Talk = 'ds_4_at_3_event_8_2'
	royal_guard_1.Interactable.Talk = 'ds_4_at_3_event_8_4'
	royal_guard_2.Interactable.Talk = 'ds_4_at_3_event_8_5'
end
--endregion

--region event_9
-- 9번 이벤트 / 기다림의 끝(289) 퀘스트 클리어 시에만 존재함.
function local_class:enter_event_npc_9_zone()
	local grand_mother = self.get_event_npc(9, 1)
	local kid = self.get_event_npc(9, 2)

	self.current_event_npc_trigger = self.current_event_npc_trigger | self.event_npc_trigger_enum.event_9

	-- 할머니 (right, tired, idle) : 여기저기 부서지고 온통 난리로구나.
	speech_bubble_util.show_speech_bubble_async(grand_mother, { key = 'ds_4_at_3_event_9_1' })

	-- 할머니 (right, tired, idle) : 너와 기사님이 애써 지켜준 그 나무는 무사히 잘 있을런지…
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	speech_bubble_util.show_speech_bubble_async(grand_mother, { key = 'ds_4_at_3_event_9_2' })

	-- 손자 (left, idle, nod x 1) : 걱정 마세요, 할머니.
	music_player_util.play_sfx_one_shot('01_rustle_01')
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	character_util.set_animation_n_times(kid, { name = 'nod' })
	speech_bubble_util.show_speech_bubble_async(kid, { key = 'ds_4_at_3_event_9_3' })

	-- 손자 (left, smile, idle) : 아까 높은 곳에 올라가서 보고 왔는데, 끄떡도 없이 잘 서있던 걸요?
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	character_util.set_emotion(kid, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(kid, { key = 'ds_4_at_3_event_9_4' })

	-- 할머니 (right, smile, idle) : 그래, 그렇다면 다행이로구나.
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	character_util.set_emotion(grand_mother, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(grand_mother, { key = 'ds_4_at_3_event_9_5' })

	music_player_util.play_sfx_one_shot('01_rustle_01')
	-- 할머니 (right, smile, nod x 1) : 네 할아버지가 분명 어디선가 지켜주고 있는 모양이야.
	character_util.set_animation_n_times(grand_mother, { name = 'nod' })
	speech_bubble_util.show_speech_bubble_async(grand_mother, { key = 'ds_4_at_3_event_9_6' })

	-- 이후 원라인으로 전환
	-- 할머니 : 너와 기사님이 지켜준 나무는 잘 있을런지…
	-- 손자 : 걱정 마세요. 끄떡도 없이 잘 서있던 걸요?
	grand_mother.Interactable.Talk = 'ds_4_at_3_event_9_7'
	kid.Interactable.Talk = 'ds_4_at_3_event_9_8'
end
--endregion

--region event_10
-- 10번 이벤트 / 뱀파이어 장로와 마족 대표
function local_class:enter_event_npc_10_zone()
	local elder = self.get_event_npc(10, 1)
	local rep = self.get_event_npc(10, 2)
	local elder_son = self.get_event_npc(10, 3)
	local aide = self.get_event_npc(10, 4)

	self.current_event_npc_trigger = self.current_event_npc_trigger | self.event_npc_trigger_enum.event_10

	music_player_util.play_sfx_one_shot('01_rustle_01')
	-- 뱀파이어 장로 (right, sleep_deep, question) : 뱀파이어와 마족의 피가 섞인 새 통치자라…
	character_util.set_emotion(elder, { name = 'sleep_deep' })
	character_util.set_anim(elder, { name = 'question', loop = false })
	speech_bubble_util.show_speech_bubble_async(elder, { key = 'ds_4_at_3_event_10_1' })

	-- 뱀파이어 장로 (right, smile, idle) : 오랜 반목과 불협화음, 차별과 혐오…
	character_util.set_emotion(elder, { name = 'smile' })
	character_util.remove_anim(elder)
	speech_bubble_util.show_speech_bubble_async(elder, { key = 'ds_4_at_3_event_10_2' })

	-- 뱀파이어 장로 (right, smile, idle) : 이 모든 게 결국엔… 새 시대를 위한 요람 역할을 해줬군.
	speech_bubble_util.show_speech_bubble_async(elder, { key = 'ds_4_at_3_event_10_2_1' })

	--마족 대표 (left, idle, nod x 1) : 뱀파이어와 마족의 화합을 위하여.
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_animation_n_times(rep, { name = 'nod' })
	speech_bubble_util.show_speech_bubble_async(rep, { key = 'ds_4_at_3_event_10_3' })

	music_player_util.play_sfx_one_shot('01_rustle_01')
	-- 장로 (right, idle, nod)
	character_util.set_animation_n_times_async(elder, { name = 'nod' })

	-- 장로 아들, 수행원 (smile, release x 2) : 새로운 데몬샤이어를 위하여!
	-- 장로와 마족  대표는 위 대사 하지 않음
	music_player_util.play_sfx_one_shot('01_male_shout_01')
	music_player_util.play_sfx_one_shot('01_female_shout_01')
	character_util.set_emotion(elder_son, { name = 'smile' })
	character_util.set_emotion(aide, { name = 'smile' })
	character_util.set_animation_n_times(elder_son, { name = 'release', count = 2, sfx = '01_swing_01' })
	character_util.set_animation_n_times(aide, { name = 'release', count = 2, sfx = '01_swing_01' })
	speech_bubble_util.show_speech_bubble(elder_son, { key = 'ds_4_at_3_event_10_4' })
	speech_bubble_util.show_speech_bubble_async(aide, { key = 'ds_4_at_3_event_10_4' })

	--이후 원라인 전환.
	--원로 : 뱀파이어와 마족의 피가 섞인 새 통치자라…
	--마족 대표 : 뱀파이어와 마족의 화합을 위하여.
	--아들 : 새로운 데몬샤이어를 위하여!
	--수행원 : 새로운 데몬샤이어를 위하여!
	elder.Interactable.Talk = 'ds_4_at_3_event_10_1'
	rep.Interactable.Talk = 'ds_4_at_3_event_10_3'
	elder_son.Interactable.Talk = 'ds_4_at_3_event_10_4'
	aide.Interactable.Talk = 'ds_4_at_3_event_10_4'
end
--endregion

--region event_11
-- 11번 이벤트 / 자동차와 배달부
function local_class:enter_event_npc_11_zone()
	local courier = self.get_event_npc(11, 1)
	local royal_guard = self.get_event_npc(11, 2)

	self.current_event_npc_trigger = self.current_event_npc_trigger | self.event_npc_trigger_enum.event_11

	-- 뱀파이어 로얄가드 (left, sleep_deep, question) : 피라미드 지하도에서 과속 및 난폭운전 하셨죠?
	music_player_util.play_sfx_one_shot('01_rustle_01')
	speech_bubble_util.show_speech_bubble_async(royal_guard, { key = 'ds_4_at_3_event_11_1' })

	-- 배달부 (right, scared, idle) : 네? 피라미드에 지하도가 있어요? 저는 전혀…
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	speech_bubble_util.show_speech_bubble_async(courier, { key = 'ds_4_at_3_event_11_2' })

	-- 뱀파이어 로얄가드 (left, attack, cross_arm) : 파손된 피라미드 지하 시설에서 스키드 마크가 여럿 발견되었는데…
	character_util.set_emotion(royal_guard, { name = 'attack' })
	character_util.set_anim(royal_guard, { name = 'cross_arm' })
	speech_bubble_util.show_speech_bubble_async(royal_guard, { key = 'ds_4_at_3_event_11_3' })

	-- 뱀파이어 로얄가드 (left, attack, release x2 ) : 데몬샤이어에서 그런 드리프트가 가능한 차량은 한 대밖에 없죠.
	music_player_util.play_sfx_one_shot('03_dialogue_ready_01')
	character_util.set_animation_n_times(royal_guard, { name = 'release', count = 2, sfx = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(royal_guard, { key = 'ds_4_at_3_event_11_4' })

	-- 배달부 (right, surprised, idle): 네? 대체 무슨…!!!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	character_util.set_emotion(courier, { name = 'surprise' })
	speech_bubble_util.show_speech_bubble_async(courier, { key = 'ds_4_at_3_event_11_5' })

	-- 뱀파이어 로얄가드 (left, mad, release x 3) : 다유다 AE86 차주!!! 소중한 문화 유산에서 대체 무슨 짓을 한 겁니까!!!
	music_player_util.play_sfx_one_shot('01_male_shout_01')
	character_util.set_emotion(royal_guard, { name = 'mad' })
	character_util.set_animation_n_times(royal_guard, { name = 'release', count = 3, sfx = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(royal_guard, { key = 'ds_4_at_3_event_11_6' })

	royal_guard.Interactable.Talk = 'ds_4_at_3_event_11_6'
	courier.Interactable.Talk = 'ds_4_at_3_event_11_5'
end
--endregion

--region req_id
function local_class:get_new_req_id(func_name)
	if self.req_id_list[func_name] == nil then
		self.req_id_list[func_name] = 0
	end

	self.req_id_list[func_name] = self.req_id_list[func_name] + 1

	return self.req_id_list[func_name]
end

function local_class:get_req_id(func_name)
	return self.req_id_list[func_name]
end

function local_class:dispose_req_id()
	for key, value in pairs(self.req_id_list) do
		value = value + 1
	end
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
