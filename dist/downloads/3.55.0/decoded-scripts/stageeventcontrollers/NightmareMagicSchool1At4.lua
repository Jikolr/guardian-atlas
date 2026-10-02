local local_class = newclass("NightmareMagicSchool1At4Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.ford_name = 'ford_anglia'

	-- 플레이어가 자동차와 같은 층에 있는지
	self.ford_floor = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')

	local ford = get_character(self.ford_name)
	stage.BattleManager:AddToNoAssassination(ford)
	-- 자동차 레벨 UI 제거
	field_ui_manager:RemoveUI(ford, CS.Oak.FieldUiType.CharacterStats)

	ford.Hitbox = CS.Oak.Hitbox(vector(3, 1, 1))

	-- 스타피스 획득 여부 체크
	if stage_progress:HasStarPiece('ford_star_piece') then
		character_util.convert_to_npc(ford)
		ford.Interactable = CS.Oak.PublishInteractable.Create()
		character_util.set_anim(ford, { name = 'idle_4' })
		for i = 1, 2 do
			local student = get_character('ford_' .. i)
			student.Position = vector(99, 0, 99)
		end
	end

	unity_object_pool.GetOrCreate('test_empty_effect')
	unity_object_pool.GetOrCreate('FX_Common_Jump_small')
end

function local_class:need_on_launch()
	local main_quest = user_progress:GetStartedQuest(86)
	return main_quest ~= nil and main_quest.InnerProgress == 3
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)

	local ford = get_character(self.ford_name)

	if lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then

		if lua_helper.reference_equals(e.FieldObject, ford) and
			lua_helper.reference_equals(e.Destroyer, user_party_leader) then

			character_util.convert_to_npc(ford)
			sp_util.play_normal_screenplay(self.destroyed_ford, self)

			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, ford) then
			sp_util.play_normal_screenplay(self.show_narration, self)
			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

		if e.Zone.Name == 'ford_floor' then
			self.ford_floor = true
			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

		if e.Zone.Name == 'ford_floor' then
			self.ford_floor = false
			return true
		end
	end

	return false
end

-- 상호작용 시 나레이션을 보여줌
function local_class:show_narration()
	local ford = get_character(self.ford_name)
	ford.Interactable = CS.Oak.NonInteractable.Instance

	stage.FieldUINarrationBox:Show()
	yield_return_func(stage.FieldUINarrationBox.SetNarration,
		stage.FieldUINarrationBox, game_string:GetString('nightmare_magicschool_4_ford_3'), 0, 1)
	stage.FieldUINarrationBox:Hide()
	wait_for_sec(0.5)

	ford.Interactable = CS.Oak.PublishInteractable.Create()
end

-- 자동차 파괴된 후 연출
function local_class:destroyed_ford()
	local ford = get_character(self.ford_name)
	camera_util.move_async(ford.Position, 1)
	wait_for_sec(1)

	local star_piece = get_field_object('ford_star_piece')
	message_system:Send(star_piece,
		CS.Oak.StarPieceAppearEvent.Create(ford.Position + vector(0, 1.5, -0.5), false))

	wait_for_sec(3)

	local marker = field:GetMarker('destroyed_ford_leader').position

	-- 자동차와 같은 층이 아니면 페이드 처리
	if not self.ford_floor then
		-- 페이트 아웃 세팅
		screen_util.fade_out_async(1, unity_class.color.black, 'linear')

		party_util.position_party(marker, 'down', 'arc')
		camera_util.move(marker)
		wait_for_sec(0.5)

		screen_util.fade_in_async(1, unity_class.color.black, 'linear')
	else
		camera_util.move(marker, 1)
		party_util.align_party(marker + unity_class.vector3.back, 'up', 1, 'arc')
	end

	character_util.set_direction(user_party_leader, 'left')
	character_util.set_anim(user_party_leader,
		{ name = 'victory_get', loop = false, sfx_name = '01_stage_intro_jump_01' })
	wait_for_sec(1.5)

	character_util.remove_anim(user_party_leader)
	character_util.set_direction(user_party_leader, 'down')


	local students = {
		get_character('ford_1'),
		get_character('ford_2')
	}

	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	-- 자, 잠깐!
	speech_bubble_util.show_speech_bubble_async(students[1],
		{ key = 'nightmare_magicschool_4_ford_4', skip = true, bubble_type = 'shout',
		  world_pos = user_party_leader.Position + vector(-0.75, 0, -4.5) })

	-- 계단 중심으로 카메라 이동
	camera_util.move(marker + unity_class.vector3.back, 1)

	local sfx_dash = music_player_util.play_sfx({ sfx_name = '01_dash_01', loop = true })
	for _, v in pairs(students) do
		v.Position = v.Position + 2.5 * unity_class.vector3.left
		local pos = v.Position + 12 * unity_class.vector3.forward
		character_util.move_to(v, pos, 2, nil, true, true)
	end
	wait_for_sec(2)
	sfx_dash:Stop()

	music_player:PlaySfxOneShot('01_player_jump_01')
	-- 학생 2명 더블 점프
	for _, v in pairs(students) do character_util.normal_jump(v) end
	wait_for_sec(0.3)
	for _, v in pairs(students) do character_util.normal_jump(v) end
	wait_for_sec(0.3)

	for _, v in pairs(students) do
		character_util.set_anim(v, { name = 'embarrassed' })
	end

	music_player:PlaySfxOneShot('03_runaway_01')
	-- 너, 너 이 자식! 그걸 부수면 어떻게 해!
	speech_bubble_util.show_speech_bubble_async(students[1],
		{ key = 'nightmare_magicschool_4_ford_5', skip = true })

	-- 우리 아버지가 직접 마법으로 개조한 건데!
	speech_bubble_util.show_speech_bubble_async(students[2],
		{ key = 'nightmare_magicschool_4_ford_6', skip = true })

	for _, v in pairs(students) do
		character_util.remove_anim_and_emotion(v)
	end

	character_util.set_direction(students[2], 'left')
	character_util.set_emotion(students[2], { name = 'cry' })
	character_util.set_anim(students[2], { name = 'release', sfx_name = '01_swing_01' })

	music_player:PlaySfxOneShot('03_dialogue_sadness_01')
	-- 아버지가 아시면 난 끝장이야!
	speech_bubble_util.show_speech_bubble_async(students[2],
		{ key = 'nightmare_magicschool_4_ford_7', skip = true })

	character_util.remove_anim(students[2])

	character_util.set_direction(students[1], 'down')
	character_util.set_emotion(students[1], { name = 'mad' })
	character_util.shake(students[1], 0.04, 5)

	music_player:PlaySfxOneShot('01_rustle_01')
	-- 으으… 용서할 수 없어…
	speech_bubble_util.show_speech_bubble_async(students[1],
		{ key = 'nightmare_magicschool_4_ford_8', skip = true })

	-- 학생들로 카메라 줌인 + 이동
	camera_util.resize_to(3, 1)
	camera_util.move_async(marker + 2 * unity_class.vector3.back, 1)

	character_util.stop_shake(students[1])
	character_util.remove_emotion(students[1])
	character_util.set_direction(students[1], 'up')
	character_util.set_anim(students[1], { name = 'cast2' })

	music_player:PlaySfxOneShot('02_magic_heal_03')
	-- set_bgm: Field(bgm_magic_school_main) -> Muted
	music_player_util.play_stage_music({ state = 'muted', mix = 2 })
	-- 아바다...
	speech_bubble_util.show_speech_bubble_async(students[1],
		{ key = 'nightmare_magicschool_4_ford_9', skip = true })

	music_player:PlaySfxOneShot('01_dark_magician_01')
	music_player:PlaySfxOneShot('01_earthquake_01')
	field:Tint('ford', unity_class.color.black, 1, 0.5)
	camera_util.shake(0.2, 99)
	wait_for_sec(1)

	character_util.set_emotion(students[2], { name = 'surprise' })
	character_util.normal_jump_async(students[2])

	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	-- 앗, 그 주문은?! 안 돼, 래리!
	speech_bubble_util.show_speech_bubble_async(students[2],
		{ key = 'nightmare_magicschool_4_ford_10', skip = true })

	party_util.set_emotion('surprise')
	camera_util.cancel_shake()

	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	-- 케밥!!!
	speech_bubble_util.show_speech_bubble_async(students[1],
		{ key = 'nightmare_magicschool_4_ford_11', skip = true, bubble_type = 'shout' })

	character_util.remove_anim(students[1])
	character_util.remove_emotion(students[2])
	character_util.set_direction(students[2], 'up')

	field:RemoveTint('ford')
	-- set_bgm: Muted -> Field(bgm_magic_school_main)
	music_player_util.play_stage_music({ state = 'field', mix = 2 })

	-- 다시 계단으로 카메라 줌아웃 + 이동
	camera_util.resize_to_default(1)
	camera_util.move_async(marker + unity_class.vector3.back, 1)

	party_util.remove_emotion()
	character_util.show_emoticon_async(user_party_leader, nil, 'question')

	-- 하늘에서 떨어지는 음식들
	local drop_item_sprite = { 'apple', 'baked_potato', 'banana_perfect', 'banquet', 'candy', 'canned_soup',
							   'carrot', 'cheesecake', 'ham', 'chocolate_bar'}

	local drop_end_pos = {
		user_party_leader.Position + vector(-2, 0, 1),
		user_party_leader.Position + vector(4, -1, -2),
		user_party_leader.Position + vector(-4, -1, 1),
		user_party_leader.Position + vector(4, -1, 2),
		user_party_leader.Position + vector(-2, -1, -3),
		user_party_leader.Position + vector(-3.5, -1, 3),
		user_party_leader.Position + vector(3.5, -1, 0),
		user_party_leader.Position + vector(-4.5, -1, -3.5),
		user_party_leader.Position + vector(1.5, 0, 0.5),
		user_party_leader.Position + vector(1.7, -1, -3)
	}

	for k, v in pairs(drop_end_pos) do
		coroutine_manager:StartCoroutine(
			stage.StageGameObject, util.cs_generator(self.fall_item, self, drop_item_sprite[k], v))
		wait_for_sec(0.1)
	end
	wait_for_sec(3)

	character_util.set_direction(students[2], 'left')
	character_util.set_emotion(students[2], { name = 'tired' })
	-- ...그걸 틀리냐…
	speech_bubble_util.show_speech_bubble_async(students[2],
		{ key = 'nightmare_magicschool_4_ford_12', skip = true })

	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	character_util.set_direction(students[1], 'right')
	character_util.set_emotion(students[1], { name = 'blush' })
	-- 뭐, 뭐! 뭘 틀렸다고 그래, 의도대로 됐구만!
	speech_bubble_util.show_speech_bubble_async(students[1],
		{ key = 'nightmare_magicschool_4_ford_13', skip = true })

	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	character_util.remove_emotion(students[1])
	character_util.set_direction(students[1], 'up')
	-- 그걸로 케밥이나 해 먹어라!
	speech_bubble_util.show_speech_bubble_async(students[1],
		{ key = 'nightmare_magicschool_4_ford_14', skip = true, bubble_type = 'shout' })

	local pos = students[1].Position + 5 * unity_class.vector3.back
	character_util.move_to_async(
		students[1], pos, nil, 7, true, true, true)

	-- ...에휴.
	speech_bubble_util.show_speech_bubble_async(students[2],
		{ key = 'nightmare_magicschool_4_ford_15', skip = true })

	pos = students[2].Position + 5 * unity_class.vector3.back
	character_util.move_to_async(
		students[2], pos, nil, 7, true, true, true)

	for _, v in pairs(students) do
		v.Position = vector(99, 0, 99)
	end

	camera_util.resize_to_default(1)
	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })

	ford.Interactable = CS.Oak.PublishInteractable.Create()
end

-- 아이템이 하늘에서 떨어지도록
function local_class:fall_item(sprite_name, end_pos)
	local start_pos = end_pos + 10 * unity_class.vector3.up

	-- 아이템 세팅
	local empty_preset = unity_object_pool.GetOrCreate('test_empty_effect')
	local smoke_preset = unity_object_pool.GetOrCreate('FX_Common_Jump_small')
	local empty = empty_preset:Instantiate(start_pos)

	local shadow_setter = empty:GetComponent(typeof(CS.Oak.StageShadowSetter))
	local main_sprite = empty.transform:Find('projectiles'):GetComponent(typeof(CS.CustomSprite))
	local shadow_sprite = empty.transform:Find('shadow'):GetComponent(typeof(CS.CustomSprite))

	if shadow_setter == nil or main_sprite == nil or shadow_sprite == nil then
		return
	end

	main_sprite.SpriteName = sprite_name
	shadow_sprite.SpriteName = sprite_name

	main_sprite:Rebuild()
	shadow_sprite:Rebuild()

	-- 낙하 계산
	local fall_calculator = CS.CalculatorFreeFall.Create(0, 19.6, start_pos.y, 1)

	fall_calculator:ScaleTime(2)
	fall_calculator:SetElasticity(0.4)

	local last_bounce = 0
	local current_y = start_pos.y

	while not fall_calculator:IsDone() do
		local dt = unity_class.time.deltaTime

		fall_calculator:Proceed(dt, end_pos.y)
		current_y = fall_calculator:GetDistance()

		if current_y <= end_pos.y then
			current_y = end_pos.y
		end

		shadow_setter.Position = vector_util.get_x0z(end_pos, current_y + 0.2)

		if last_bounce ~= fall_calculator:NumBounced() then
			last_bounce = fall_calculator:NumBounced()

			local effect = smoke_preset:Instantiate(empty.transform.localPosition)
			effect.transform.localScale = 0.4 * unity_class.vector3.one

			fall_calculator:ScaleTime(1)

			music_player:PlaySfxOneShot('01_player_jump_01')

			coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.alpha_fade, self, main_sprite, shadow_sprite, empty))
		end

		coroutine.yield(nil)
	end
end

-- 아이템 알파 페이드
function local_class:alpha_fade(main_sprite, shadow_sprite, empty)
	local duration = 1

	local main_color = main_sprite.TintColor
	local shadow_color = shadow_sprite.TintColor
	local save_main_color = main_color

	local alpha_calculator = CS.Oak.FloatLerpCalculator()
	alpha_calculator:Set(main_color.a, 0, duration)

	local time_passed = 0

	while time_passed < duration do
		alpha_calculator:UpdateFrame(unity_class.time.deltaTime)
		time_passed = time_passed + unity_class.time.deltaTime

		main_color.a = alpha_calculator.CurrentValue
		main_color.r = alpha_calculator.CurrentValue
		main_color.g = alpha_calculator.CurrentValue
		main_color.b = alpha_calculator.CurrentValue

		shadow_color.a = alpha_calculator.CurrentValue

		main_sprite.TintColor = main_color
		shadow_sprite.TintColor = shadow_color

		main_sprite:Rebuild()
		shadow_sprite:Rebuild()

		coroutine.yield(nil)
	end

	empty.transform.position = vector(99, 0, 99)

	main_sprite.SpriteName = ""
	shadow_sprite.SpriteName = ""

	main_color.a = save_main_color.a
	main_color.r = save_main_color.r
	main_color.g = save_main_color.g
	main_color.b = save_main_color.b

	shadow_color.a = 1

	main_sprite.TintColor = main_color
	shadow_sprite.TintColor = shadow_color

	main_sprite:Rebuild()
	shadow_sprite:Rebuild()

	empty:Dispose()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
