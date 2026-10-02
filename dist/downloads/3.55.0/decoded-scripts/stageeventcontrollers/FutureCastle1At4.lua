local local_class = newclass('FutureCastle1At4Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.stew_id = 20192

	--난민들이 머리 위로 들 짐 리스트
	self.refugee_load_list = {}

	self.laila_food_count = 0
	self.has_seen_laila = false
	self.laila_out = true

	self.marty_talk_over = false

	self.laila_talk_over = false
	self.laila_ongoing = false


	-- 서쪽 경비 대화 이벤트 체크
	self.west_soldier_conv_start = false

	-- 아이템 스펙 이름
	self.rachels_hat_item_spec_name = 'rachel_hat_hang'

	-- 오브젝트를 가져오는 함수
	self.get_gravestone = function() return get_field_object('rachels_gravestone') end

	self.rachels_hat_item = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.ConvertSwitchChangedEvent), 'on_event')


	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	if stage.Name == 'futurecastle_1_4' then
		quest_util.load_pool_resource(
			'stage_item'
		)
		self:agency_iron_teatan_parts_load()
	end
end

function local_class:need_on_launch()

	local futurecastle_main_quest_id = 151
	local q = user_progress:GetStartedQuest(futurecastle_main_quest_id)

	self:stage_event_setting(q.InnerProgress, q.IsComplete)
	return true
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, get_character('west_soldier_5')) or
		lua_helper.reference_equals(e.Target, get_character('west_soldier_6')) then
		if self.west_soldier_conv_start then
			return
		else
			self.west_soldier_conv_start = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.soldier_conversation, self))
			return
		end
	end

	if lua_helper.reference_equals(e.Target, get_character('laila')) and not self.laila_talk_over then
		self.laila_talk_over = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_with_laila, self))
		return true

	elseif lua_helper.reference_equals(e.Target, get_character('marty')) and not self.marty_talk_over then
		self.marty_talk_over = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.marty_event, self))
		return true

	end
	return true
end

function local_class:on_zone_leave_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) and e.Zone.Name == 'laila_food' and e.FullLeave then
		self.laila_out = true
	end
	return true
end

function local_class:on_zone_enter_event(e)

	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if e.Zone.Name == 'laila_food' and self.laila_out == true and self.laila_food_count <= 2 and self.laila_ongoing == false then
			self.laila_out = false
			self.laila_ongoing = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.laila_food_zone_event, self))
		end
	end

	return true
end

function local_class:on_stage_loaded_event(e)
	local gravestone = self.get_gravestone()
	local item_data = game_data_service.GetData('ItemData')
	local item_id = item_data:GetSpec(self.rachels_hat_item_spec_name).Id

	self.rachels_hat_item = drop_item_util.create_item({ pos = gravestone.Position + vector(0.125, 1, 0), itemid = item_id, notforinven = true, lootstate = 'dontfindlooter' })

	return false
end


function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	local futurecastle_main_quest_id = 151
	local q = user_progress:GetStartedQuest(futurecastle_main_quest_id)

	--공주 파티 합류 및 파티원 전원 날리기
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self, q.InnerProgress, q.IsComplete))
end

function local_class:dispose()
	self.cs_controller = nil
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ConvertSwitchChangedEvent))

	local laila = get_character('laila')
	if laila.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		laila.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
	local marty = get_character('marty')
	if marty.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		marty.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
	self:agency_iron_teatan_parts_dispose()

	if self.rachels_hat_item ~= nil then
		self.rachels_hat_item:ConsumeComplete()
		self.rachels_hat_item = nil
	end
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	end
	if event_type == typeof(CS.Oak.ConvertSwitchChangedEvent) then
		-- FIXME: 청홍 스위치에서는 소리가 나지 않고 벽에서만 나고 있는데 벽 그리드가 플레이어 그리드와 달라서 소리가 나지 않는 문제 임시 해결
		music_player_util.play_sfx({ sfx_name = '01_blueredwall_01', type_priority = 'event', player_priority = 'npc' })
	end
	return false
end

-- 아이언 티탄 헤드 로드
function local_class:agency_iron_teatan_parts_load()
	self.res_holder = CS.Foundations.ResourceHolder()
	self.parts_go = {}
	self.parts_vfo = {}

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.res_holder, "theatres/iron_teatans_head", "iron_teatans_head", function(prefab)
		local obj = CS.UnityEngine.GameObject.Instantiate(prefab)
		self.iron_teatan_head1 = obj:AddComponent(typeof(CS.Oak.IronTeatansHead))
		self.iron_teatan_head1.Name = 'iron_teatan_head_1'
		self.iron_teatan_head1.FieldObjectBehaviour = CS.Oak.HoldableObjectBehaviour()
		self.iron_teatan_head1.CrashBehaviour = CS.Oak.WallCrashBehaviour()
		self.iron_teatan_head1.ActiveState = active_state('enabled')

		self.iron_teatan_head1:Init()
		self.iron_teatan_head1.Position = vector(54.5, 1, 2.5)

		self.iron_teatan_head1.Transform:GetChild('iron_teatans_head').localRotation = unity_class.quaternion.Euler(0, -90, 0)
		message_system:Publish(CS.Oak.AddFieldObjectEvent.Create(self.iron_teatan_head1))
		self.parts_go[#self.parts_go + 1] = obj
	end)

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.res_holder, "theatres/iron_teatans_head", "iron_teatans_head", function(prefab)
		local obj = CS.UnityEngine.GameObject.Instantiate(prefab)
		self.iron_teatan_head2 = obj:AddComponent(typeof(CS.Oak.IronTeatansHead))
		self.iron_teatan_head2.Name = 'iron_teatan_head_2'
		self.iron_teatan_head2.FieldObjectBehaviour = CS.Oak.HoldableObjectBehaviour()
		self.iron_teatan_head2.CrashBehaviour = CS.Oak.WallCrashBehaviour()
		self.iron_teatan_head2.ActiveState = active_state('enabled')

		self.iron_teatan_head2:Init()
		self.iron_teatan_head2.Position = vector(54.5, 1, -3.5)

		self.iron_teatan_head2.Transform:GetChild('iron_teatans_head').localRotation = unity_class.quaternion.Euler(0, -90, 0)
		message_system:Publish(CS.Oak.AddFieldObjectEvent.Create(self.iron_teatan_head2))
		self.parts_go[#self.parts_go + 1] = obj
	end)

end


-- 전시용 아이언 티탄 파츠 자원 해제
function local_class:agency_iron_teatan_parts_dispose()
	for _, vfo in ipairs(self.parts_vfo) do
		vfo:Dispose()
	end

	for _, go in ipairs(self.parts_go) do
		CS.UnityEngine.GameObject.Destroy(go)
	end

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
	end

	self.res_holder = nil
	self.iron_teatan_head1 = nil
	self.iron_teatan_head2 = nil
end

function local_class:soldier_script_setting()
	local option = true
	for i = 1, 14 do
		local temp = get_character('west_soldier_' .. i)
		if i == 5 or i == 6 then
			-- 인터랙터블 세팅
			-- 인베이더가 침입하는 기색이 보이면 바로 아이샤님께 보고하게!
			-- 네 알겠습니다!
			temp.Interactable:AddListener(self.cs_controller)

		else
			if i % 2 == 1 then
				-- 홀수일 경우 원라인 스크립트 추가
				-- 번갈아가며 세팅

				if option then
					-- 현재 인베이더 침입 경계 근무중 입니다!
					temp.Interactable.Talk = 'futurecastle_main_a_s17_20'
					option = false
				else
					-- 근무 중 이상 무!
					temp.Interactable.Talk = 'futurecastle_main_a_s17_21'
					option = true

				end

			end

		end

	end

end

-- 인터랙트하면 서쪽 경비 군인들 대화하는 이벤트
function local_class:soldier_conversation()
	-- 밖에 설치
	-- self.west_soldier_conv_start = true

	local west_5 = get_character('west_soldier_5')
	local west_6 = get_character('west_soldier_6')

	-- 인베이더가 침입하는 기색이 보이면 바로 아이샤님께 보고하게!
	character_util.set_anim(west_5, { name = 'release', loop = true })
	character_util.set_emotion(west_5, { name = 'attack', loop = true })
	speech_bubble_util.show_speech_bubble_async(west_5, { key = 'futurecastle_main_a_s17_22', skip = false})
	character_util.remove_anim_and_emotion(west_5)

	-- 네 알겠습니다!
	character_util.set_anim(west_6, { name = 'salute', loop = false })
	character_util.set_emotion(west_6, { name = 'attack', loop = true })
	speech_bubble_util.show_speech_bubble_async(west_6, { key = 'futurecastle_main_a_s17_23', skip = false})
	character_util.remove_anim_and_emotion(west_6)

	wait_for_sec(0.5)

	self.west_soldier_conv_start = false
end

function local_class:marty_event()
	user_party:StopAndDisableControl()
	stage.FieldUIManager:Hide()
	local marty = get_character('marty')

	character_util.align_party(marty.Position, 'right', 1, 'linear')

	--거기 너! 못보던 놈인데...
	character_util.set_anim(marty, {name = 'dagger_idle', loop = true, scale = 1})
	character_util.set_emotion(marty, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(marty, {key = 'futurecastle_main_a_s19_93', skip = true})

	--선택지
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait_for_branch = true
	local choice = 0
	-- 너도 못보던 놈인데...
	branches:Add({
		Text = game_string:GetString('futurecastle_main_a_s19_95'),
		Tendency = CS.Oak.TalkTendency.Forced,
		Callback = function()
			wait_for_branch = false
			choice = 0
		end
	})
	-- 나는 가디언이야!
	branches:Add({
		Text = game_string:GetString('futurecastle_main_a_s19_94'),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})
	local choice_state = CS.Oak.UI.AnswerChoiceState()
	choice_state.Branchs = branches
	choice_state.Talker = marty

	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)
	while wait_for_branch do
		coroutine.yield(nil)
	end

	if choice == 0 then
		character_util.set_anim(user_party_leader, {name = 'dagger_idle', loop = true, scale = 1})
		character_util.set_emotion(user_party_leader, {name = 'attack', loop = true})
		wait_for_sec(1)

		character_util.remove_anim_and_emotion(marty)
		character_util.normal_double_jump(marty)

		-- 잠깐만... 너...
		character_util.set_anim(marty, {name = 'question', loop = false, scale = 1})
		character_util.set_emotion(marty, {name = 'tired', loop = true})
		speech_bubble_util.show_speech_bubble_async(marty, {key = 'futurecastle_main_a_s19_97', skip = true})
	elseif choice == 1 then
		character_util.set_anim(user_party_leader, {name = 'victory_get', loop = false, scale = 1})
		character_util.set_emotion(user_party_leader, {name = 'smile', loop = true})
		wait_for_sec(1.2)

		-- 가디언...? 너...
		character_util.set_anim(marty, {name = 'question', loop = false, scale = 1})
		character_util.set_emotion(marty, {name = 'tired', loop = true})
		speech_bubble_util.show_speech_bubble_async(marty, {key = 'futurecastle_main_a_s19_96', skip = true})
	end

	-- 혹시... 마리안님의 친구분 아니예요?
	character_util.set_anim(marty, {name = 'sing', loop = true, scale = 1})
	character_util.set_emotion(marty, {name = 'smile', loop = true})
	speech_bubble_util.show_speech_bubble_async(marty, {key = 'futurecastle_main_a_s19_98', skip = true})

	-- 지난 10년동안 마리안님이 종종 얘기 하셨어요.
	character_util.set_anim(marty, {name = 'release', loop = true, scale = 1})
	speech_bubble_util.show_speech_bubble_async(marty, {key = 'futurecastle_main_a_s19_99', skip = true})

	-- 인베이더의 침략을 막기위해 당신과 마리안님이 함께 싸워왔던 이야기들...
	character_util.set_anim(marty, {name = 'bomb_idle', loop = true, scale = 1})
	character_util.set_emotion(marty, {name = 'sleep_deep', loop = true})
	speech_bubble_util.show_speech_bubble_async(marty, {key = 'futurecastle_main_a_s19_100', skip = true})

	-- 당신만 함께 있었다면 일이 이렇게는 안 됐을 거라고...
	character_util.set_anim(marty, {name = 'cast', loop = true, scale = 1})
	character_util.set_emotion(marty, {name = 'tired', loop = true})
	speech_bubble_util.show_speech_bubble_async(marty, {key = 'futurecastle_main_a_s19_101', skip = true})
	character_util.remove_anim_and_emotion(marty)

	--선택지
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait_for_branch = true
	local choice = 0
	-- 이런 저런 사정이 있어서...
	branches:Add({
		Text = game_string:GetString('futurecastle_main_a_s19_102'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
			choice = 0
		end
	})
	-- 나도 잠시 쉴 필요가 있잖아?
	branches:Add({
		Text = game_string:GetString('futurecastle_main_a_s19_103'),
		Tendency = CS.Oak.TalkTendency.Forced,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})
	local choice_state = CS.Oak.UI.AnswerChoiceState()
	choice_state.Branchs = branches
	choice_state.Talker = marty

	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)
	while wait_for_branch do
		coroutine.yield(nil)
	end

	if choice == 0 then
		character_util.set_anim(user_party_leader, {name = 'cast', loop = true, scale = 1})
		character_util.set_emotion(user_party_leader, {name = 'tired', loop = true})
		wait_for_sec(1)
		character_util.remove_anim_and_emotion(user_party_leader)

	elseif choice == 1 then
		character_util.set_anim(user_party_leader, {name = 'bomb_idle', loop = true, scale = 1})
		character_util.set_emotion(user_party_leader, {name = 'doyagao', loop = true})
		wait_for_sec(1)
		character_util.remove_anim_and_emotion(user_party_leader)

	end

	-- ... 어린 시절의 마티주니어였다면... 당신을 원망했을지도 몰라요.
	character_util.set_anim(marty, {name = 'cast', loop = true, scale = 1})
	character_util.set_emotion(marty, {name = 'tired', loop = true})
	speech_bubble_util.show_speech_bubble_async(marty, {key = 'futurecastle_main_a_s19_104', skip = true})

	--하지만 지금의 저는 달라요.
	character_util.set_anim(marty, {name = 'bomb_idle', loop = true, scale = 1})
	character_util.set_emotion(marty, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(marty, {key = 'futurecastle_main_a_s19_105', skip = true})

	--그동안의 노고... 진심으로 감사드립니다!
	character_util.set_anim(marty, {name = 'cast', loop = true, scale = 1})
	character_util.set_emotion(marty, {name = 'smile', loop = true})
	speech_bubble_util.show_speech_bubble_async(marty, {key = 'futurecastle_main_a_s19_106', skip = true})

	--저도 힘을 내 볼게요!
	character_util.set_anim(marty, {name = 'cast2', loop = true, scale = 1})
	character_util.set_emotion(marty, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(marty, {key = 'futurecastle_main_a_s19_107', skip = true})
	character_util.remove_anim_and_emotion(marty)

	if marty.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		marty.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	marty.Interactable.Talk = 'futurecastle_main_a_s19_107'

	stage.FieldUIManager:Show()
	user_party:ResetControllers()
end

--라일라 배급소 이벤트
function local_class:laila_food_zone_event()
	local laila = get_character('laila')

	if 	self.has_seen_laila == false then
		character_util.set_animation_n_times(laila, { name = 'success', count = 2 })
		speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_51', skip = false, bubble_type = 'shout'})

	end

	self.has_seen_laila = true

	if self.laila_out == true then
		self.laila_ongoing = false
		return
	end

	local refugee_numbers = {12, 3, 8}

	local refugee_end_pos = {vector(111, 0, 14), vector(111, 0, 32), vector(111, 0, 28)}

	local refugee_end_dir = {'up', 'left', 'down'}

	for i = self.laila_food_count + 1, 3 do
		local refugee = get_character('refugee_food_'..refugee_numbers[i])
		refugee.Interactable.Talk = ''
		character_util.remove_anim_and_emotion(refugee)
		refugee:HideWeapon(true)

		if i > 1 then
			character_util.move_waypoint_async(refugee, vector(106, 0, 21), 2, false, 'stop', 'floor', 'down')
		end

		if self.laila_out == true then
			self.laila_ongoing = false
			return
		end

		wait_for_sec(0.7)

		if self.laila_out == true then
			self.laila_ongoing = false
			return
		end

		local stew = drop_item_util.create_item(
			{itemid = self.stew_id, notforinven = true, pos = laila.Position, target = refugee.Position + vector(0, 0, -0.2),
				lootstate = 'dontfindlooter', skip_text = true, sprscale = 0.5, showoncharacter = true})

		--라일라 특제 선인장 스튜입니다!
		character_util.set_anim(laila, { name = 'release', loop = false })
		speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_72', skip = false})
		character_util.remove_anim(laila)

		if self.laila_out == true then
			stew.ConsumeTarget = refugee
			character_util.remove_anim_and_emotion(refugee)
			character_util.move_waypoint(refugee, {vector(111, 0, 21), refugee_end_pos[i]}, 3, false, 'stop', 'floor', refugee_end_dir[i])
			refugee.Interactable.Talk = 'futurecastle_main_a_s19_74'

			self.laila_food_count = self.laila_food_count + 1
			self.laila_ongoing = false
			return
		end

		character_util.set_direction(refugee, 'left')
		character_util.set_anim(refugee, { name = 'eat', loop = true })
		character_util.set_emotion(refugee, { name = 'idle', loop = true })
		wait_for_sec(0.8)

		if self.laila_out == true then
			stew.ConsumeTarget = refugee
			character_util.remove_anim_and_emotion(refugee)
			character_util.move_waypoint(refugee, {vector(111, 0, 21), refugee_end_pos[i]}, 3, false, 'stop', 'floor', refugee_end_dir[i])
			refugee.Interactable.Talk = 'futurecastle_main_a_s19_74'

			self.laila_food_count = self.laila_food_count + 1
			self.laila_ongoing = false
			return
		end

		character_util.set_direction(refugee, 'down')

		stew.ConsumeTarget = refugee
		character_util.remove_anim_and_emotion(refugee)

		--라일라 님! 항상 감사합니다!
		character_util.set_anim(refugee, { name = 'cast', loop = true })
		character_util.set_emotion(refugee, { name = 'smile', loop = true })
		speech_bubble_util.show_speech_bubble_async(refugee, {key = 'futurecastle_main_a_s19_50', skip = false})

		character_util.remove_anim_and_emotion(refugee)

		--바깥으로 이동.
		character_util.move_waypoint(refugee, {vector(111, 0, 21), refugee_end_pos[i]}, 3, false, 'stop', 'floor', refugee_end_dir[i])
		refugee.Interactable.Talk = 'futurecastle_main_a_s19_74'

		self.laila_food_count = self.laila_food_count + 1

		if self.laila_out == true then
			self.laila_ongoing = false
			return
		end

	end

	character_util.set_anim(laila, { name = 'release', loop = true })
	speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_75', skip = false})
	character_util.remove_anim(laila)

	character_util.move_waypoint(laila, vector(106, 0, 18.7), 3, false, 'stop', 'floor', 'down')

	character_util.set_direction(laila, 'right')
	character_util.set_anim(laila, { name = 'eat', loop = true })
	speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_76', skip = false})

	self.laila_ongoing = false

	if laila.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		laila.Interactable:AddListener(self.cs_controller)
	end
end

--라일라에게 말을 걸어 대화.
function local_class:talk_with_laila()
	user_party:StopAndDisableControl()
	stage.FieldUIManager:Hide()
	local laila = get_character('laila')

	character_util.align_party(laila.Position, 'right', 1, 'linear')

	character_util.set_direction(laila, 'right')
	--아! 안녕하세요! 스튜는 잠시 준비중...
	character_util.set_anim(laila, {name = 'idle', loop = true, scale = 1})
	character_util.set_emotion(laila, {name = 'smile', loop = true})
	speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_77', skip = true})

	character_util.show_emoticon_async(laila, nil, CS.Oak.EmoticonType.Question)

	-- 혹시... 저희 어디선가 만난 적이 있었나요?
	character_util.set_anim(laila, {name = 'question', loop = false, scale = 1})
	character_util.set_emotion(laila, {name = 'tired', loop = true})
	speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_78', skip = true})

	--선택지
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait_for_branch = true
	local choice = 0
	-- 아니. 난 처음 보는데.
	branches:Add({
		Text = game_string:GetString('futurecastle_main_a_s19_79'),
		Tendency = CS.Oak.TalkTendency.Forced,
		Callback = function()
			wait_for_branch = false
			choice = 0
		end
	})
	-- 사막에서 만났던가...?
	branches:Add({
		Text = game_string:GetString('futurecastle_main_a_s19_80'),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})
	local choice_state = CS.Oak.UI.AnswerChoiceState()
	choice_state.Branchs = branches
	choice_state.Talker = laila

	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)
	while wait_for_branch do
		coroutine.yield(nil)
	end

	if choice == 0 then
		character_util.set_anim(user_party_leader, {name = 'bomb_idle', loop = true, scale = 1})
		character_util.set_emotion(user_party_leader, {name = 'idle', loop = true})
		wait_for_sec(1)
		character_util.remove_anim_and_emotion(user_party_leader)

		-- 아니에요. 분명히 어디선가...
		character_util.set_anim(laila, {name = 'idle', loop = true, scale = 1})
		character_util.set_emotion(laila, {name = 'attack', loop = true})
		speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_81', skip = true})
	elseif choice == 1 then
		character_util.set_anim(user_party_leader, {name = 'cross_arm', loop = true, scale = 1})
		character_util.set_emotion(user_party_leader, {name = 'tired', loop = true})
		wait_for_sec(1)
		character_util.remove_anim_and_emotion(user_party_leader)

		-- 사막...?
		character_util.set_anim(laila, {name = 'idle', loop = true, scale = 1})
		character_util.set_emotion(laila, {name = 'attack', loop = true})
		speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_82', skip = true})
	end
	--이모티콘
	character_util.show_emoticon_async(laila, nil, CS.Oak.EmoticonType.Notice)

	-- 생각났어요! 마빈 아저씨의 친구분이시죠?
	character_util.set_anim(laila, {name = 'cast', loop = true, scale = 1})
	character_util.set_emotion(laila, {name = 'smile', loop = true})
	speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_83', skip = true})
	-- 그 때 저 구해주셨었잖아요!
	character_util.set_anim(laila, {name = 'victory_get', loop = false, scale = 1})
	character_util.set_emotion(laila, {name = 'smile', loop = true})
	speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_84', skip = true})

	--선택지
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait_for_branch = true
	local choice = 0
	-- ... 여전히 기억이 없는 걸?
	branches:Add({
		Text = game_string:GetString('futurecastle_main_a_s19_85'),
		Tendency = CS.Oak.TalkTendency.Forced,
		Callback = function()
			wait_for_branch = false
			choice = 0
		end
	})
	-- 혹시... 마빈이 아끼던 선인장 피클 소녀?
	branches:Add({
		Text = game_string:GetString('futurecastle_main_a_s19_86'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})
	local choice_state = CS.Oak.UI.AnswerChoiceState()
	choice_state.Branchs = branches
	choice_state.Talker = laila

	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)
	while wait_for_branch do
		coroutine.yield(nil)
	end


	if choice == 0 then
		character_util.set_anim(user_party_leader, {name = 'bomb_idle', loop = true, scale = 1})
		character_util.set_emotion(user_party_leader, {name = 'tired', loop = true})
		wait_for_sec(1)
		character_util.remove_anim_and_emotion(user_party_leader)

		-- 하긴... 요즘같은 때에는 충격으로 기억을 잃는 경우도 있다고 하니...
		character_util.set_anim(laila, {name = 'idle', loop = true, scale = 1})
		character_util.set_emotion(laila, {name = 'attack', loop = true})
		speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_87', skip = true})

		-- 그래도 잘 됐어요... 꼭 하고 싶은 말이 있었거든요!
		character_util.set_anim(laila, {name = 'cast', loop = true, scale = 1})
		character_util.set_emotion(laila, {name = 'smile', loop = true})
		speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_87_1', skip = true})

	elseif choice == 1 then
		character_util.set_anim(user_party_leader, {name = 'cross_arm', loop = true, scale = 1})
		character_util.set_emotion(user_party_leader, {name = 'tired', loop = true})
		wait_for_sec(1)
		character_util.remove_anim_and_emotion(user_party_leader)

		-- 맞아요! 선인장 피클 소녀, 라일라예요!
		character_util.set_anim(laila, {name = 'idle', loop = true, scale = 1})
		character_util.set_emotion(laila, {name = 'attack', loop = true})
		speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_88', skip = true})

		character_util.set_anim(user_party_leader, {name = 'nod', loop = true, scale = 1})
		character_util.set_emotion(user_party_leader, {name = 'smile', loop = true})
		wait_for_sec(1)
		character_util.remove_anim_and_emotion(user_party_leader)

	end

	-- 아저씨! 그땐 정말 고마웠어요! 이렇게 다시 뵈니 정말 좋네요!
	character_util.set_anim(laila, {name = 'sing', loop = true, scale = 1})
	character_util.set_emotion(laila, {name = 'smile', loop = true})
	speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_89', skip = true})

	character_util.set_anim(laila, {name = 'idle', loop = true, scale = 1})
	character_util.set_emotion(laila, {name = 'tired', loop = true})
	wait_for_sec(1)

	if laila.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		laila.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	-- 마빈 아저씨도... 아저씨를 다시 만나면 좋아하셨을텐데...
	speech_bubble_util.show_speech_bubble_async(laila, {key = 'futurecastle_main_a_s19_90', skip = true})
	laila.Interactable.Talk = 'futurecastle_main_a_s19_90'

	stage.FieldUIManager:Show()
	user_party:ResetControllers()
end

--모든 스테이지 이벤트 세팅을 관리하는 곳
function local_class:stage_event_setting(innerprogress, IsComplete)
	--섹션 구별 없이 실행되어야하는 함수들

	-- 서쪽 경비 대사 세팅
	self:soldier_script_setting()

	self:refugee_load_setting()

	--인비지블 월에 아이템 만들어서 할당.
	self:s17_set_refugee_hold_load()

	--여러 난민들 세팅
	self:set_refugee_talk()
	if innerprogress >= 18 then
		--탑승장 난민
		for i = 1, 14 do
			local refugee = get_character('refugee_'..i)
			if i <= 9 then
				character_util.set_anim(refugee, { name = 'idle', loop = true })
				character_util.set_emotion(refugee, { name = 'idle', loop = true })
				if i % 3 == 0 then
					--우리 이제 곧 떠날 수 있는거겠지?
					refugee.Interactable.Talk = 'futurecastle_main_a_s19_54'
				elseif i % 3 == 1 then
					--어서 이곳을 떠야...
					refugee.Interactable.Talk = 'futurecastle_main_a_s19_57'
				elseif i % 3 == 2 then
					--비공정에 타기 전에 한번 더 확인해봐야해.
					refugee.Interactable.Talk = 'futurecastle_main_a_s19_61'
				end

			elseif i == 10 then
				--필요한 건 다 챙겼나 마지막으로 확인해봐야지. 감자 3포대... 그리고...
				refugee.Interactable.Talk = 'futurecastle_main_a_s19_73'
			elseif i == 11 then
				--비공정에 타기 전에 한번 더 확인해봐야해.
				refugee.Interactable.Talk = 'futurecastle_main_a_s19_61'
			elseif i == 12 then
				--어서 이곳을 떠야...
				refugee.Interactable.Talk = 'futurecastle_main_a_s19_57'
			elseif i == 13 then
				--우리 이제 곧 떠날 수 있는거겠지?
				refugee.Interactable.Talk = 'futurecastle_main_a_s19_54'
			elseif i == 14 then
				--우리 이제 곧 떠날 수 있는거겠지?
				refugee.Interactable.Talk = 'futurecastle_main_a_s19_59'
			end

		end
	end

	--섹션이 20 이상일 때 999 처리 한 후, 이후 함수 실행하지 않음.
	if innerprogress > 19 or IsComplete then
		for i = 1, 4 do
			local refugee = get_character('refugee_battle2_'..i)
			character_util.set_position(refugee, vector(999, 0, 999))
		end
		return
	end
	--섹션이 20 이하일 때만 아래쪽 실행.
	--섹션 20 전용 처리
	if innerprogress >= 19 then
		for i = 1, 4 do
			local refugee = get_character('refugee_battle2_'..i)
			character_util.set_position(refugee, vector(999, 0, 999))
		end
	end

end

--배급소 난민 / 탑승장 난민 세팅
function local_class:set_refugee_talk()

	--배급소 난민
	local laila = get_character('laila')

	for i = 1, 18 do
		local refugee = get_character('refugee_food_'..i)

		if i <= 12 then
			if i % 2 == 0 then
				--라일라 님! 항상 감사합니다!
				refugee.Interactable.Talk = 'futurecastle_main_a_s19_50'
				character_util.set_anim(refugee, { name = 'idle', loop = true })
				character_util.set_emotion(refugee, { name = 'idle', loop = true })
			else
				--죽을만큼 힘들어도... 라일라 님의 스튜는 언제나 맛있어.
				refugee.Interactable.Talk = 'futurecastle_main_a_s19_52'
				if i % 3 == 1 then
					character_util.set_anim(refugee, { name = 'idle', loop = true })
					character_util.set_emotion(refugee, { name = 'tired', loop = true })
				else
					character_util.set_anim(refugee, { name = 'idle', loop = true })
					character_util.set_emotion(refugee, { name = 'idle', loop = true })
				end

			end

		else
			if refugee.Direction == CS.Oak.Direction.Right then
				character_util.set_anim(refugee, { name = 'seat', loop = true })
				character_util.set_emotion(refugee, { name = 'tired', loop = true })
				drop_item_util.create_item(
					{itemid = self.stew_id, notforinven = true, pos = refugee.Position, target = refugee.Position + vector(0.3, 0, 0),
						lootstate = 'dontfindlooter', skip_text = true, sprscale = 0.5, showoncharacter = true})
			elseif refugee.Direction == CS.Oak.Direction.Left then
				character_util.set_anim(refugee, { name = 'seat', loop = true })
				character_util.set_emotion(refugee, { name = 'tired', loop = true })
				drop_item_util.create_item(
					{itemid = self.stew_id, notforinven = true, pos = refugee.Position, target = refugee.Position + vector(-0.3, 0, 0),
						lootstate = 'dontfindlooter', skip_text = true, sprscale = 0.5, showoncharacter = true})

			elseif refugee.Direction == CS.Oak.Direction.Down then
				character_util.set_anim(refugee, { name = 'meditation', loop = true })
				character_util.set_emotion(refugee, { name = 'tired', loop = true })
				drop_item_util.create_item(
					{itemid = self.stew_id, notforinven = true, pos = refugee.Position, target = refugee.Position + vector(0, 0, -0.3),
						lootstate = 'dontfindlooter', skip_text = true, sprscale = 0.5, showoncharacter = true})
			end

			if i == 13 then
				--오늘도 몇 차례나 인베이더들이 습격했대요.
				refugee.Interactable.Talk = 'futurecastle_main_a_s19_53'

			elseif i == 14 or i == 15 then
				--어서 이곳을 떠야...
				refugee.Interactable.Talk = 'futurecastle_main_a_s19_54'

			elseif i == 16 then
				--내 것 좀 더 먹을래?
				refugee.Interactable.Talk = 'futurecastle_main_a_s19_55'

			elseif i == 17 or i == 18 then
				--고마워...
				refugee.Interactable.Talk = 'futurecastle_main_a_s19_56'

			end
		end
	end

	--배급소 제국군
	for i = 1, 2 do
		local soldier = get_character('soldier_food_'..i)
		soldier.Interactable.Talk = 'futurecastle_main_a_s19_66'
	end

	--탑승장 제국군
	for i = 5, 8 do
		local soldier = get_character('soldier_air_'..i)
		if i % 2 == 0 then
			soldier.Interactable.Talk = 'futurecastle_main_a_s19_91'
		else
			soldier.Interactable.Talk = 'futurecastle_main_a_s19_92'
		end

	end

	--마티주니어
	for i = 1, 4 do
		local teatan = get_character('marty_robot_'..i)
		if i <= 2 then
			teatan.Interactable.Talk = 'futurecastle_main_a_s19_110'
			character_util.set_emotion(teatan, {name = 'attack', loop = true})
		elseif i == 3 then
			teatan.Interactable.Talk = 'futurecastle_main_a_s19_111'
			character_util.set_emotion(teatan, {name = 'attack', loop = true})
		else
			teatan.Interactable.Talk = 'futurecastle_main_a_s19_112'
			character_util.set_emotion(teatan, {name = 'attack', loop = true})
		end
	end

	for i = 1, 3 do
		local teatan = get_character('marty_normal_'..i)
		if i <= 2 then
			teatan.Interactable.Talk = 'futurecastle_main_a_s19_108'
			if teatan.Direction ~= CS.Oak.Direction.Up then
				character_util.set_anim(teatan, {name = 'eat', loop = true, scale = 1})
			end

		else
			teatan.Interactable.Talk = 'futurecastle_main_a_s19_109'
			character_util.set_anim(teatan, {name = 'eat', loop = true, scale = 1})
		end
	end

	local marty = get_character('marty')
	if marty.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		marty.Interactable:AddListener(self.cs_controller)
	end
end

-- 인비저블 월에 아이템 달기
function local_class:set_refugee_load(num, item_num)
	-- 짐으로 사용할 아이템들 (스프라이트 나오면 수정해야 함)
	local load_item_id = {'refugee_load_a', 'refugee_load_b', 'refugee_load_c', 'refugee_food'}

	-- 투명 오브젝트에 아이템을 붙일 때 사용하는 함수. load_pool_resource 에서도 똑같이 사용
	local get_stage_item = function() return unity_object_pool.GetOrCreate('stage_item') end

	local refugee_load = get_field_object('refugee_load_' .. num)
	local load_item = get_stage_item():Instantiate(refugee_load.Position, unity_class.quaternion.identity, refugee_load.Transform)

	local stage_item = load_item:GetComponent(typeof(CS.Oak.StageItem))
	local item_spec_name = load_item_id[item_num]
	stage_item:SetItem(item_spec_name)
	stage_item.ShadowActive = true

	if item_num < 4 then
		stage_item.transform.localScale = vector(0.8, 0.8, 0.8)

	end

	return refugee_load
end

-- 난민 짐 스프라이트 일괄 세팅
function local_class:refugee_load_setting()
	local item_num = 1
	local total = 15

	for i = 1, total do
		local load = self:set_refugee_load(i , item_num)

		if item_num >= 4 then
			item_num = 1
		else
			item_num = item_num + 1
		end

		table.insert(self.refugee_load_list, load)
	end

end

-- 섹션 17에서 일괄적으로 난민들에게 짐 들려주기
function local_class:s17_set_refugee_hold_load()
	local item_num = 1
	local item_total = 15

	local holdup_load = function(fo)
		if item_num >= item_total then
			return

		else
			command_util.execute_holdup(fo, self.refugee_load_list[item_num], fo.Position, 0, false)
			item_num = item_num + 1

		end

	end

	local load_set_list = {}
	-- refugee_bn_~ 짐 세팅
	for i = 1, 15 do
		local temp = get_character('refugee_bn_' .. i)

		if i % 2 == 0 then
			holdup_load(temp)
		elseif i==3 then
			holdup_load(temp)
		elseif i==7 then
			holdup_load(temp)
		end

	end

	load_set_list = {true, true, true, false, false, false, true, true}
	-- refugee_~ 짐 세팅
	for i = 1, 8 do
		local temp = get_character('refugee_' .. i)

		if load_set_list[i] then
			holdup_load(temp)
		end

	end

end

--주인공 혼자 들어오도록 하는 함수
function local_class:opening_routine(innerprogress, IsComplete)
	local party_list = {}

	for i = 0, user_party.Count - 1 do
		local cur_party_member = user_party[i]

		table.insert(party_list, cur_party_member)
	end

	for i = 1, #party_list do
		if i ~= 1 then
			character_util.convert_to_npc(party_list[i])
			party_list[i].ActiveState = CS.Oak.ActiveState.Disabled
		end
	end

	local princess = get_character('princess')
	character_util.remove_anim_and_emotion(princess)
	character_util.convert_to_party_member(princess, user_party, true)
	character_util.remove_anim_and_emotion(princess)
	character_util.set_position(princess, vector(-1, 0, 0))

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, 'linear')

	coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(vector(0, 0, -0.5),
			CS.Oak.Direction.Right, game_string:GetString(stage.Name)))

	user_party:StopAndDisableControl()
	stage.FieldUIManager:Hide()

	if innerprogress >= 20 then
		-- 서브 이벤트 달성을 위해 비공정이 떠나기 전 시간대에서 플레이를 하게 됩니다.
		field_ui_util.show_narration_async({ key = 'futurecastle_1_4_after_narration' })

		get_field_object('stg4_flag').Position = vector(88, 0, -30.5)
	end

	stage.FieldUIManager:Show()
	user_party:ResetControllers()

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}