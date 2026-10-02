local local_class = newclass("NightmareDesert1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.pickaxes = {}
	self.saw_lazy_prisoner = false
	self.saw_prison_officer = false
	self.break_check = false
	self.grid_check = false

	self.door_name = 'item_door_1'

	-- 커스텀 스테이트 이름
	self.custom_state = {
		-- door1이 열렸는지
		open_door_1 = 0
	}
end

function local_class:load_resource()

	get_character('desertelf_prison_officer').Interactable:AddListener(self.cs_controller)

	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	unity_object_pool.GetOrCreate("FX_Common_SmokeScreen")

	character_util.set_anim(get_character('desertelf_prison_officer'), { name = 'push' })

	-- 문 열려있을 경우 NPC 제거
	local door = get_field_object(self.door_name)
	if door.FieldObjectBehaviour.Opened then
		self.saw_prison_officer = true
		local desertelf_prison_officer = get_character('desertelf_prison_officer')
		desertelf_prison_officer.Interactable:RemoveRelatedEvent(self.cs_controller)
		character_util.set_active_state(desertelf_prison_officer, "disabled")
	end

	-- 스타피스 획득 여부 체크
	if CS.Oak.StageProgress.Current:HasStarPiece('desert_starpiece') then
		self.saw_lazy_prisoner = true
		local desertelf_prisoner = get_character('desertelf_prisoner')
		desertelf_prisoner.Interactable.Talk = 'nightmare_desert_1_lazy_10'
	else
		message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	end

	-- 문 열려있을 경우 NPC 제거
	if stage_progress:GetCustomData(self.custom_state.open_door_1) then
		self.saw_prison_officer = true
		local desertelf_prison_officer = get_character('desertelf_prison_officer')
		desertelf_prison_officer.Interactable:RemoveRelatedEvent(self.cs_controller)
		character_util.set_active_state(desertelf_prison_officer, "disabled")

		local door = get_field_object(self.door_name)
		local opened_door = get_field_object(self.door_name .. '_open')

		door.Position, opened_door.Position = opened_door.Position, door.Position
	end

	-- 타일맵에서 문을 미리 열어놓은채로 설정이 되지 않아서 스테이지 시작하면 바로 열어둠.
	message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name .. '_open'))

	return
end

function local_class:need_on_launch()
	-- 메인퀘스트 진행도에 따라 launch를 빼앗아 온다.
	local main_quest = user_progress:GetStartedQuest(90)
	return main_quest == nil or main_quest.InnerProgress < 1
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	local desertelf_prison_officer = get_character('desertelf_prison_officer')
	if desertelf_prison_officer ~= nil then
		desertelf_prison_officer.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if self.pickaxes ~= nil then
		for _, value in ipairs(self.pickaxes) do
			value:ConsumeComplete()
			value = nil
		end
		self.pickaxes = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.InteractEvent) then

		if lua_helper.reference_equals(e.Target, get_field_object('pickaxe_dummy')) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_narration))
		end
		if lua_helper.reference_equals(e.Target, get_character('desertelf_prison_officer')) then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.desertelf_prison_officer, self))
		end
		return true

	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then

		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if e.Zone.Name == 'lazy_zone' and self.grid_check and self.break_check and not self.saw_lazy_prisoner then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.lazy_prisoner, self))
				return true
			end
		end

	elseif event_type == typeof(CS.Oak.StageLoadedEvent) then

		self:setting_pickaxe()
		return true

	elseif event_type == typeof(CS.Oak.FieldObjectDestroyedEvent) and
			lua_helper.reference_equals(e.FieldObject, get_field_object('starpiece_rock')) then

		if not self.saw_lazy_prisoner then
			if self.grid_check then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.lazy_prisoner, self))
			else
				self.break_check = true
			end
		end
		return true
	elseif event_type == typeof(CS.Oak.CameraGridEnterEvent) then
		if not lua_helper.reference_equals(e.FieldObject, user_party_leader) and
				not lua_helper.reference_equals(e.FieldObject, user_party) then
			return false
		end
		if e.CameraGrid.name == 'lazy_grid' then
			if not self.saw_lazy_prisoner then
					self.grid_check = true
				return true
			end
		end
	elseif event_type == typeof(CS.Oak.CameraGridLeaveEvent) then
		if not self.saw_lazy_prisoner then
			if not lua_helper.reference_equals(e.FieldObject, user_party_leader) and
					not lua_helper.reference_equals(e.FieldObject, user_party) then
				return false
			end
			if e.CameraGrid.name == 'lazy_grid' then
				self.grid_check = false
				return true
			end
		end
	end

	return false
end

-- 곡괭이 세팅
function local_class:setting_pickaxe()
	local dummy = get_field_object('pickaxe_dummy')
	dummy.Hitbox = CS.Oak.Hitbox(vector(3, 1, 3))
	local item_data = CS.Oak.GameDataService.GetData("ItemData")
	for i = 0, 3 do
		for j = -3, 3 do
			local item_axe = drop_item_util.create_item({
				pos = dummy.Position + vector(j * 0.4, 0, -i * 0.2),
				itemid = item_data:GetSpec('prison_pickaxe').Id,
				notforinven = true, lootstate = "dontfindlooter" })
			local rad = CS.UnityEngine.Random.value
			item_axe.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, rad * 360, 0)
			item_axe.ShadowTransform.localRotation = unity_class.quaternion.Euler(90, rad * 360, 0)
			table.insert(self.pickaxes, item_axe)
		end
	end
end

-- 버려진 곡괭이들 더미 나레이션
function local_class:start_narration()
	CS.Oak.Party.MyParty:StopAndDisableControl()
	stage.FieldUINarrationBox:Show()
	yield_return(stage.FieldUINarrationBox, "SetNarration",
			game_string:GetString("nightmare_desert_1_lazy_pickaxe"), 0, 1.0)
	yield_return(stage.FieldUINarrationBox, "HideAnimation")
	CS.Oak.Party.MyParty:ResetControllers()
end

-- NPC 후일담: 사막의 샤피라 이벤트
function local_class:desertelf_prison_officer()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local desertelf_prison_officer = get_character('desertelf_prison_officer')

	local pos = desertelf_prison_officer.Position + unity_class.vector3.left * 1.5
	user_party:PositionParty(pos, CS.Oak.Direction.Right, 1, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	-- 신관님, 죄송합니다…
	camera_util.resize_to(3.5, 1)
	character_util.set_emotion(desertelf_prison_officer, { name = 'idle' })
	speech_bubble_util.show_speech_bubble_async(desertelf_prison_officer,
			{ key = 'nightmare_desert_1_desert_shapira_1', skip = true })


	-- 아… 알고 있습니다. 모든 책임은 제가 질 테니…
	camera_util.resize_to(3, 1)
	character_util.set_emotion(desertelf_prison_officer, { name = 'surprise' })
	speech_bubble_util.show_speech_bubble_async(desertelf_prison_officer,
			{ key = 'nightmare_desert_1_desert_shapira_2', skip = true })

	-- 아… 저기… 할복은 그래도 좀…
	music_player:PlaySfxOneShot('03_runaway_01')
	camera_util.resize_to(2, 1)
	character_util.set_emotion(desertelf_prison_officer, { name = 'surprise' })
	character_util.set_anim(desertelf_prison_officer, { name = 'embarrassed' })
	speech_bubble_util.show_speech_bubble_async(desertelf_prison_officer,
			{ key = 'nightmare_desert_1_desert_shapira_3', skip = true })

	-- 뒤돌아 봄
	character_util.set_direction(desertelf_prison_officer, character_util.get_direction('left'))
	character_util.set_emotion(desertelf_prison_officer, { name = 'idle' })
	character_util.remove_anim(desertelf_prison_officer)
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	-- 으아악!!
	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	music_player:PlaySfxOneShot('01_player_jump_01')
	camera_util.resize_to_default(0.3)
	camera_util.shake(0.4, 0.5)
	character_util.jump(desertelf_prison_officer, 1, 0.5)
	character_util.set_emotion(desertelf_prison_officer, { name = 'surprise' })
	character_util.set_anim(desertelf_prison_officer, { name = 'embarrassed' })
	wait_all({
		util.cs_generator(character_util.move_to_async, desertelf_prison_officer, desertelf_prison_officer.Position + unity_class.vector3.right * 0.6, 0.5, nil, false, false),
		util.cs_generator(speech_bubble_util.show_speech_bubble_async, desertelf_prison_officer, { key = 'nightmare_desert_1_desert_shapira_4', skip = true })
	})

	-- 뭐, 뭐야 넌!
	character_util.set_direction(desertelf_prison_officer, character_util.get_direction('left'))
	character_util.set_emotion(desertelf_prison_officer, { name = 'mad' })
	character_util.set_anim(desertelf_prison_officer, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(desertelf_prison_officer,
			{ key = 'nightmare_desert_1_desert_shapira_5', skip = true })

	-- 이렇게 붙잡힐 순 없지!
	character_util.set_direction(desertelf_prison_officer, character_util.get_direction('right'))
	character_util.set_emotion(desertelf_prison_officer, { name = 'attack' })
	character_util.remove_anim(desertelf_prison_officer)
	speech_bubble_util.show_speech_bubble_async(desertelf_prison_officer,
			{ key = 'nightmare_desert_1_desert_shapira_6', skip = true })

	-- 대신관님 만세!!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_direction(desertelf_prison_officer, character_util.get_direction('left'))
	character_util.set_anim(desertelf_prison_officer, { name = 'cast2' })
	speech_bubble_util.show_speech_bubble_async(desertelf_prison_officer,
			{ key = 'nightmare_desert_1_desert_shapira_7', skip = true })

	character_util.set_anim(desertelf_prison_officer, { name = 'release', loop = false })
	music_player:PlaySfxOneShot('01_throw_01')
	wait_for_sec(0.45)--467

	-- 연막
	music_player:PlaySfxOneShot('02_wolf_boss_bomb_01')
	local obj = unity_object_pool.GetOrCreate("FX_Common_SmokeScreen"):Instantiate(desertelf_prison_officer.Position)
	obj.transform.localScale = unity_class.vector3.one * 1.5
	--
	party_util.set_emotion({ name = 'confused' })
	party_util.set_anim({ name = 'prostrate' })
	--
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	-- 문 앞까지 이동
	local waypoints = create_generic_list(unity_class.vector3)
	waypoints:Add(vector(-30.5, 0, 8))
	waypoints:Add(vector(-35, 0, 8))

	character_util.remove_anim(desertelf_prison_officer)
	character_util.move_waypoint_async(desertelf_prison_officer, { vector(-30.5, 0, 8), vector(-35, 0, 8), vector(-35, 0, 15) }, 7, true, nil, nil, nil, true)
	character_util.set_active_state(desertelf_prison_officer, "disabled")

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 미리 열어둔 문이랑 교체함.
	local door = get_field_object(self.door_name)
	local opened_door = get_field_object(self.door_name .. '_open')
	door.Position, opened_door.Position = opened_door.Position, door.Position

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	music_player:PlaySfxOneShot('01_rustle_01')
	party_util.shake(0.02, 0.5)
	wait_for_sec(1)
	music_player:PlaySfxOneShot('01_rustle_01')
	party_util.shake(0.02, 0.5)
	wait_for_sec(1)

	party_util.remove_emotion()
	party_util.remove_animation()

	--local mario_jump_list = {}
	--for i = 0, user_party.Count - 1 do
	--	table.insert(mario_jump_list, util.cs_generator(character_util.mario_jump_async, user_party[i], 'right', 0.3, 0.5))
	--end
	--
	--wait_all(mario_jump_list)

	music_player:PlaySfxOneShot('01_player_popup_01')
	for i = 0, user_party.Count - 1 do
		character_util.mario_jump_new(user_party[i], 'right', 0.3, 0.5)
	end

	wait_for_sec(0.3)

	-- 이벤트 종료
	local stage_custom = stage_progress:SetCustomData(self.custom_state.open_door_1, true)
	coroutine.yield(CS.Oak.NetworkManager.ApiConnection:SendSetCustom(stage.StageId, stage_custom))

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 게으른 죄수 이벤트
function local_class:lazy_prisoner()
	local desertelf_prisoner = get_character('desertelf_prisoner')

	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	-- 으악!
	music_player:PlaySfxOneShot('01_player_jump_01')
	music_player:PlaySfxOneShot('02_goblin_hit_01')
	character_util.set_emotion(desertelf_prisoner, { name = 'surprise' })
	character_util.set_anim(desertelf_prisoner, { name = 'jump', loop = false })
	character_util.jump(desertelf_prisoner, 0.5, 0.3)
	speech_bubble_util.show_speech_bubble(desertelf_prisoner,
			{ key = 'nightmare_desert_1_lazy_1', skip = true})

	-- 스타피스 등장
	local star_piece = get_field_object('desert_starpiece')
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(star_piece.Position))
	coroutine.yield(coroutine_class.wait_for_sec(2.0))

	-- 죄수에게 이동
	local pos = desertelf_prisoner.Position + unity_class.vector3.right * 1.5
	user_party:PositionParty(pos, CS.Oak.Direction.Left, 1, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	character_util.set_anim(desertelf_prisoner, { name = 'idle', loop = true })
	character_util.set_direction(desertelf_prisoner, character_util.get_direction('left'))
	music_player:PlaySfxOneShot('01_swing_01')
	coroutine.yield(coroutine_class.wait_for_sec(0.8))

	character_util.set_direction(desertelf_prisoner, character_util.get_direction('right'))
	music_player:PlaySfxOneShot('01_swing_01')
	coroutine.yield(coroutine_class.wait_for_sec(0.8))

	character_util.set_emotion(desertelf_prisoner, { name = 'idle' })
	character_util.set_anim(desertelf_prisoner, { name = 'idle' })
	coroutine.yield(coroutine_class.wait_for_sec(1.0))

	-- ...아. 나 채석장에서 잠들었구나
	speech_bubble_util.show_speech_bubble_async(desertelf_prisoner,
			{ key = 'nightmare_desert_1_lazy_2', skip = true })

	-- 어떤 덩치랑 부딪혀서 채석장 안에 굴러 떨어졌거든
	music_player:PlaySfxOneShot('01_hit_npc_01')
	character_util.set_emotion(desertelf_prisoner, { name = 'tired' })
	character_util.set_anim(desertelf_prisoner, { name = 'frustration', loop = false })
	speech_bubble_util.show_speech_bubble_async(desertelf_prisoner,
			{ key = 'nightmare_desert_1_lazy_3', skip = true })

	-- 근데 바위가 자기 좋게 생겼더라고. 내 몸에 딱 맞는 크기감, 이 허리를 받쳐주는 굴곡…
	character_util.set_emotion(desertelf_prisoner, { name = 'greed' })
	character_util.set_anim(desertelf_prisoner, { name = 'prostrate', loop = false })
	music_player:PlaySfxOneShot('01_gatcha_point_01')
	speech_bubble_util.show_speech_bubble_async(desertelf_prisoner,
			{ key = 'nightmare_desert_1_lazy_4', skip = true })

	-- 흐아암. 그래서 그대로 잠들어 버렸나 봐
	character_util.set_emotion(desertelf_prisoner, { name = 'sleep' })
	character_util.set_anim(desertelf_prisoner, { name = 'prostrate', loop = false })
	music_player:PlaySfxOneShot('01_sleep_02')
	speech_bubble_util.show_speech_bubble_async(desertelf_prisoner,
			{ key = 'nightmare_desert_1_lazy_5', skip = true })

	-- 선택지: 넌 이제 자유야. / 여긴 이제 아무도 없어
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true

	branches:Add({
		Text = game_string:GetString('nightmare_desert_1_lazy_branch_1'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end })

	branches:Add({
		Text = game_string:GetString('nightmare_desert_1_lazy_branch_2'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end })

	ui_overlay_util.push_overlay(desertelf_prisoner, branches)

	while wait do
		coroutine.yield(nil)
	end

	-- 뭐 정말이야?
	music_player:PlaySfxOneShot('03_dialogue_negative_02')
	character_util.set_emotion(desertelf_prisoner, { name = 'surprise' })
	character_util.set_anim(desertelf_prisoner, { name = 'jump', loop = false })
	character_util.jump(desertelf_prisoner, 0.5, 0.3)
	speech_bubble_util.show_speech_bubble_async(desertelf_prisoner,
			{ key = 'nightmare_desert_1_lazy_6', skip = true })

	-- 잠깐. 그러면… 나 여기서 자고 있을 필요가 없잖아?
	character_util.set_direction(desertelf_prisoner, character_util.get_direction('down'))
	character_util.set_emotion(desertelf_prisoner, { name = 'idle' })
	character_util.set_anim(desertelf_prisoner, { name = 'question', loop = false })
	speech_bubble_util.show_speech_bubble_async(desertelf_prisoner,
			{ key = 'nightmare_desert_1_lazy_7', skip = true })

	-- 간수들이 쓰던 푹신푹신한 침대에서 잘 수 있겠어!
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	character_util.set_direction(desertelf_prisoner, character_util.get_direction('right'))
	character_util.set_emotion(desertelf_prisoner, { name = 'smile' })
	character_util.set_anim(desertelf_prisoner, { name = 'success', loop = true, sfx_name = '01_jump_01' })
	speech_bubble_util.show_speech_bubble_async(desertelf_prisoner,
			{ key = 'nightmare_desert_1_lazy_8', skip = true })

	-- 흐아암~ 그치만 지금은 졸리니까 낮잠부터 잔 다음에 움직여볼까~
	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	character_util.set_emotion(desertelf_prisoner, { name = 'sleep' })
	character_util.set_anim(desertelf_prisoner, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(desertelf_prisoner,
			{ key = 'nightmare_desert_1_lazy_9', skip = true })


	character_util.set_direction(desertelf_prisoner, character_util.get_direction('down'))
	character_util.set_anim(desertelf_prisoner, { name = 'sleep', loop = true })
	wait_for_sec(0.5)
	self.saw_lazy_prisoner = true

	-- 흐암~ 자유로운 것도 귀찮아…
	desertelf_prisoner.Interactable.Talk = 'nightmare_desert_1_lazy_10'
	music_player:PlaySfxOneShot('01_sleep_02')

	field_ui_manager:Show()
	user_party:ResetControllers()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}