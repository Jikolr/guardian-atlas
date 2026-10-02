local local_class = newclass('RescueSnowmanController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.snowman_kid = nil
	self.snowmans = {}

	self.need_request_rescue = false
	self.rescue_count = 0
	self.water_effect_pool = nil
	self.starpiece_name = 'rescue_snowman_star_piece'
	self.water_play_coroutine = nil

	self.hold_snowman = nil
	self.snowman_enter_zone_check_coroutine = {}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.HoldUpEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ThrowEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')

	self.water_effect_pool = unity_object_pool.GetOrCreate('fx_common_water_splash_in')

	self.snowman_kid = get_character('snowman_kid')
	for i = 1, 3 do
		self.snowmans[i] = get_character('snowman_' .. i)
	end

	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.HoldUpEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ThrowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	if self.water_play_coroutine ~= nil then
		stop_coroutine(self.water_play_coroutine)
		self.water_play_coroutine = nil
	end

	if self.water_effect_pool ~= nil then
		self.water_effect_pool:Dispose()
	end
	self.water_effect_pool = nil

	self.snowman_enter_zone_check_coroutine = nil
	self.snowman_kid = nil
	self.snowmans = nil
	self.hold_snowman = nil

	self.cs_controller = nil
end

-- fo가 snowmans 중 하나인지 찾아보고 맞으면 해당 객체의 index를, 아니면 0을 반환
function local_class:get_snowmans_index(fo)
	for i = 1, #self.snowmans do
		if lua_helper.reference_equals(fo, self.snowmans[i]) then
			return i
		end
	end

	return 0
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if e.FullEnter == false or CS.Oak.StageProgress.Current:HasStarPiece(self.starpiece_name) then return false end

		local zone_name = e.Zone.Name

		if zone_name == 'requesting_rescue' and self.need_request_rescue == true then
			if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

			self.need_request_rescue = false
			coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.requesting_rescue, self))
		elseif zone_name == 'rescue_water' then
			-- 다 구출 했을때도 연출에서 위치 이동하면서 이벤트가 작동하기 때문에, 다 구출했는지 체크함.
			if self.rescue_count < 3 then
				local index = self:get_snowmans_index(e.FieldObject)

				if index > 0 then
					self.snowman_enter_zone_check_coroutine[index] = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.snowman_enter_zone_check, self, index, self.rescue_snowman))
					return true
				end
			end
		elseif zone_name == 'wrong_water' then
			local index = self:get_snowmans_index(e.FieldObject)

			if index > 0 then
				self.snowman_enter_zone_check_coroutine[index] = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.snowman_enter_zone_check, self, index, self.thrown_wrong_water))
				return true
			end
		end
	elseif event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		if CS.Oak.StageProgress.Current:HasStarPiece(self.starpiece_name) then return false end

		local zone_name = e.Zone.Name

		if zone_name == 'rescue_water' then
			local index = self:get_snowmans_index(e.FieldObject)

			if index > 0 then
				if self.snowman_enter_zone_check_coroutine[index] ~= nil then
					stop_coroutine(self.snowman_enter_zone_check_coroutine[index])
					self.snowman_enter_zone_check_coroutine[index] = nil
				end
				return true
			end
		elseif zone_name == 'wrong_water' then
			local index = self:get_snowmans_index(e.FieldObject)

			if index > 0 then
				if self.snowman_enter_zone_check_coroutine[index] ~= nil then
					stop_coroutine(self.snowman_enter_zone_check_coroutine[index])
					self.snowman_enter_zone_check_coroutine[index] = nil
				end
				return true
			end
		end
	elseif event_type == typeof(CS.Oak.StageLoadedEvent) then
		-- 스타피스 획득 여부에 따른 스타피스 처리
		if CS.Oak.StageProgress.Current:HasStarPiece(self.starpiece_name) then
			-- 획득 세팅
			for i = 1, #self.snowmans do
				character_util.set_active_state(self.snowmans[i], 'disabled')
			end
			character_util.set_active_state(self.snowman_kid, 'disabled')
		else
			-- 미획득 세팅
			self.need_request_rescue = true
			character_util.set_emotion(self.snowman_kid, { name = 'damaged' })
			character_util.set_anim(self.snowman_kid, { name = 'idle' })
			for i = 1, #self.snowmans do
				character_util.set_direction(self.snowmans[i], 'right')
				character_util.set_anim_and_emotion(self.snowmans[i], { name = 'prostrate' }, { name = 'tired' })
			end
		end

		return true
	elseif event_type == typeof(CS.Oak.HoldUpEvent) then
		for i = 1, #self.snowmans do
			if lua_helper.reference_equals(e.Target, self.snowmans[i]) then
				self:on_hold_up_event(i)
				self.hold_snowman = e.Target
				return true
			end
		end
	elseif event_type == typeof(CS.Oak.ThrowEvent) then
		if self.hold_snowman ~= nil and lua_helper.reference_equals(e.Target, self.hold_snowman) then
			self.hold_snowman = nil
			return true
		end
	end
	return false
end

function local_class:on_hold_up_event(idx)
	-- “무, 물… 물이 필요해…”
	speech_bubble_util.show_speech_bubble(self.snowmans[idx], { key = 'nightmare_desert_2_rescue_snowman_3' })
end

-- 설인이 이벤트 존 안에 들어와있는지 아닌지 체크함
function local_class:snowman_enter_zone_check(i, func)
	local snowman = self.snowmans[i]

	-- 점프 중일 때 던졌을 때도 이벤트 존 안에 들어갈 경우 연출이 시작되어야 함.
	-- 하지만, 점프 중일 때 이미 설인이 이벤트 존 안에 들어가 있는 경우도 있음.
	-- 이미 이벤트 존 안에 있는 경우에는 ZoneEnterEvent가 다시 발생하지 않기 때문에 여기에서 코루틴으로 다시 체크함.
	-- ZoneLeaveEvent가 발생하지 않고, 플레이어가 들고 있지 않으며, 땅에 거의 떨어졌을 때 이벤트 존 안에 들어온 것으로 판단함.
	while lua_helper.reference_equals(snowman, self.hold_snowman) or snowman.Position.y > 0.1 do
		coroutine.yield(nil)
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(func, self, i))

	self.snowman_enter_zone_check_coroutine[i] = nil
end

function local_class:thrown_wrong_water(idx)
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local target = self.snowmans[idx]
	-- IFieldObjectBehaviour.ResetOnWrongPosition에 접근하지 못해 강제로 캐스팅함
	local bhv = target.CharacterBehaviour
	cast(bhv, typeof(CS.Oak.IFieldObjectBehaviour))
	if bhv ~= nil then
		bhv.ResetOnWrongPosition = false

		-- 이펙트 발생
		yield_return_func(self.create_water_effect, self, target)
		-- 영역이 좁아서 안에 들어가면 stop
		character_util.move_to(target, vector(target.Position.x, -0.7, target.Position.z))
		camera_util.move_async(target.Position, 1)
		-- 부들부들 떨며 “으, 으으… 물?”
		music_player:PlaySfxOneShot('01_rustle_01')
		character_util.shake(target, 0.02, 1)
		speech_bubble_util.show_speech_bubble_async(target, { key = 'nightmare_desert_2_rescue_snowman_4', skip = true })
		-- 마리오 점프로 일어선 뒤 “아, 상쾌해!”
		music_player:PlaySfxOneShot('01_water_splash_01')
		character_util.stop_shake(target)
		character_util.mario_jump_async(target, 'right')
		speech_bubble_util.show_speech_bubble_async(target, { key = 'nightmare_desert_2_rescue_snowman_5', skip = true })

		-- “어? 막내! 막내가 어디 갔지?”
		music_player:PlaySfxOneShot('03_dialogue_negative_02')
		character_util.set_anim(target, { name = 'down' })
		character_util.set_emotion(target, { name = 'surprise' })
		speech_bubble_util.show_speech_bubble_async(target, { key = 'nightmare_desert_2_rescue_snowman_7', skip = true })

		character_util.set_anim(target, { name = 'embarrassed' })
		-- 물에서 뛰쳐나와 방 아래로 내려가며 “막내야!”
		music_player:PlaySfxOneShot('03_runaway_01')
		music_player:PlaySfxOneShot('01_water_splash_01')
		speech_bubble_util.show_speech_bubble_async(target, { key = 'nightmare_desert_2_rescue_snowman_8', skip = true })

		music_player:PlaySfxOneShot('01_drown_01')
		screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.reset_snowman, self, idx))
		camera_util.move(user_party_leader.Position, 0, { end_target = user_party_leader })
		screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')
	end

	party_util.reset_controllers()
	field_ui_manager:Show()
end

function local_class:reset_snowman(idx)
	coroutine.yield(nil)
	local target = self.snowmans[idx]
	local marker = field:GetMarker('snowman_reset_point_' .. idx)
	character_util.set_position(target, marker.position)
	character_util.set_direction(target, marker.direction)
	character_util.set_anim_and_emotion(target, { name = 'prostrate' }, { name = 'tired' })
end
function local_class:rescue_snowman(idx)
	local target = self.snowmans[idx]
	-- IFieldObjectBehaviour.ResetOnWrongPosition에 접근하지 못해 강제로 캐스팅함
	local bhv = target.CharacterBehaviour
	cast(bhv, typeof(CS.Oak.IFieldObjectBehaviour))
	if bhv == nil then return end

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()
	-- 물에 빠져도 Reset 안되도록
	bhv.ResetOnWrongPosition = false

	-- 이펙트 발생
	yield_return_func(self.create_water_effect, self, target)

	self.rescue_count = self.rescue_count + 1
	-- 모두 구했으면 구출 완료 루틴 아니면 구출 루틴
	if self.rescue_count == 3 then
		yield_return_func(self.rescue_end, self)
	else
		character_util.move_to(target, vector(target.Position.x, -0.7, target.Position.z))
		camera_util.move_async(target.Position, 1)
		-- 꼬마, 어느 설인이냐에 따라 9 - “큰 형!” 10 - “누나!” 11 - “작은 형!” 외침.
		music_player:PlaySfxOneShot('03_dialogue_negative_01')
		character_util.look_at(self.snowman_kid, target)
		character_util.set_emotion(self.snowman_kid, { name = 'surprise' })
		speech_bubble_util.show_speech_bubble_async(self.snowman_kid,
			{ key = 'nightmare_desert_2_rescue_snowman_' .. (8 + idx), skip = true, bubble_type = 'shout' })
		-- 부들부들 떨며 “으, 으으… 물?”
		music_player:PlaySfxOneShot('01_rustle_01')
		character_util.shake(target, 0.02, 1)
		speech_bubble_util.show_speech_bubble_async(target, { key = 'nightmare_desert_2_rescue_snowman_4', skip = true })
		-- 마리오 점프로 일어선 뒤 “아, 상쾌해!”
		music_player:PlaySfxOneShot('01_water_splash_01')
		character_util.stop_shake(target)
		character_util.mario_jump_async(target, 'right')
		wait_for_sec(0.5)
		character_util.set_emotion(target, { name = 'smile' })
		character_util.set_anim(target, { name = 'idle' })
		speech_bubble_util.show_speech_bubble_async(target, { key = 'nightmare_desert_2_rescue_snowman_5', skip = true })

		-- 주인공 있는 쪽 보고 “고마워요!”
		music_player:PlaySfxOneShot('03_dialogue_positive_01')
		character_util.look_at(target, user_party_leader)
		character_util.set_emotion(target, { name = 'awesome' })
		character_util.set_anim(target, { name = 'release', sfx_name = '01_swing_01' })
		speech_bubble_util.show_speech_bubble_async(target, { key = 'nightmare_desert_2_rescue_snowman_6', skip = true })

		character_util.set_anim(target, { name = 'idle' })
		character_util.set_emotion(self.snowman_kid, { name = 'damaged' })
	end

	target.Holdable = CS.Oak.NonHoldable.Instance

	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })
	party_util.reset_controllers()
	field_ui_manager:Show()
end

function local_class:create_water_effect(fo)
	-- 땅 위에 있을 때 진행함.
	-- 오차값이 있을 수 있어 0.1 더 높게 해서 체크함
	while fo.Position.y > 0.1 do
		coroutine.yield()
	end

	music_player:PlaySfxOneShot('01_dive_01')
	self.water_effect_pool:Instantiate(fo.Position)
end

-- 구출 완료 루틴
function local_class:rescue_end()
	wait_for_sec(0.5)
	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	party_util.align_party(vector(58,0,30), 'right')

	local offsets = { vector(-2, 0, -0.5),
					  vector(-0.5, 0, 1),
					  vector(2, 0, 0) }

	local directions = { vector_util.to_direction(offsets[1] * -1) ,
						 vector_util.to_direction(offsets[2] * -1) ,
						 vector_util.to_direction(offsets[3] * -1) }
	for i = 1, 3 do
		character_util.set_anim_and_emotion(self.snowmans[i], { name = 'idle' }, { name = 'smile' })
		character_util.set_position(self.snowmans[i], self.snowman_kid.Position + offsets[i])
		character_util.set_direction(self.snowmans[i], directions[i])
	end
	character_util.set_emotion(self.snowman_kid, { name = 'smile' })
	camera_util.move(self.snowman_kid.Position, 0, { ignorecameragrids = true })
	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')
	-- 설인 가족들, smile, “와 다 모였다!” 외침.
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	speech_bubble_util.show_speech_bubble_async(self.snowman_kid, { key = 'nightmare_desert_2_rescue_snowman_12', skip = true, bubble_type = 'shout' })

	-- 누나, tired, idle, “휴, 정말 녹아 없어지는 줄 알았어.”
	character_util.set_anim_and_emotion(self.snowmans[2], { name = 'idle' }, { name = 'tired' })
	speech_bubble_util.show_speech_bubble_async(self.snowmans[2], { key = 'nightmare_desert_2_rescue_snowman_13', skip = true })
	-- 큰 형, smile, release, “막내 녀석, 용케 오아시스를 찾아내고 말이야.”
	character_util.set_anim_and_emotion(self.snowmans[1], { name = 'release', sfx_name = '01_swing_01' }, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(self.snowmans[1], { key = 'nightmare_desert_2_rescue_snowman_14', skip = true })
	-- 작은 형, smile, attack, 스플래시 이펙트로 물장구 치는 느낌, “제법인데?”
	music_player:PlaySfxOneShot('01_dive_01')
	self.water_effect_pool:Instantiate(self.snowmans[3].Position + direction_util.to_vector3(directions[3]) * 0.3)
	character_util.set_anim(self.snowmans[1], { name = 'idle' })
	character_util.set_anim_and_emotion(self.snowmans[3], { name = 'attack', sfx_name = '01_water_splash_01' }, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(self.snowmans[3], { key = 'nightmare_desert_2_rescue_snowman_15', skip = true })
	-- 꼬마, surprise, “앗 차거!” 외침.
	music_player:PlaySfxOneShot('03_runaway_01')
	character_util.set_emotion(self.snowman_kid, { name = 'surprise' })
	speech_bubble_util.show_speech_bubble_async(self.snowman_kid, { key = 'nightmare_desert_2_rescue_snowman_16', skip = true })
	-- 꼬마, 작은 형 보고 attack, 스플래시 이펙트, “으으! 전쟁 시작이다!” 외침.
	music_player:PlaySfxOneShot('01_dive_01')
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_anim(self.snowman_kid, { name = 'attack', sfx_name = '01_water_splash_01' })
	character_util.set_direction(self.snowman_kid, 'right')
	music_player:PlaySfxOneShot('01_dive_01')
	self.water_effect_pool:Instantiate(self.snowman_kid.Position - direction_util.to_vector3(directions[3]) * 0.3)
	speech_bubble_util.show_speech_bubble_async(self.snowman_kid, { key = 'nightmare_desert_2_rescue_snowman_17', skip = true, bubble_type = 'shout' })
	-- 설인들, 다 같이 awesome 표정, 각자 dance나 attack, release 애니메이션, 스플래시 이펙트로 물장구 치며 논다. 드문드문 외침 “아하하” “하하하하”
	-- 꼬마 있는 쪽에서 스타피스가 물 속에서부터 솟아올라 꼬마 앞에 드랍.
	yield_return_func(self.water_play, self, 4.5)

	-- 스타피스 생성
	-- 설인들, 모두 스타피스 쪽 보고 surprise, idle.
	for i = 1, 3 do
		character_util.set_anim_and_emotion(self.snowmans[i], { name = 'idle' }, { name = 'surprise' })
	end
	character_util.set_anim_and_emotion(self.snowman_kid, { name = 'idle' }, { name = 'surprise' })
	-- 큰 형, idle, question, “이게 뭐지…?”
	music_player:PlaySfxOneShot('02_bomb_holdup_fail_01')
	character_util.show_emoticon(self.snowman_kid, nil, CS.Oak.EmoticonType.Notice)
	character_util.set_anim_and_emotion(self.snowman_kid, { name = 'idle' }, { name = 'question' })
	speech_bubble_util.show_speech_bubble_async(self.snowman_kid, { key = 'nightmare_desert_2_rescue_snowman_20', skip = true })
	-- 누나, smile, idle, “와 예쁘다!”
	music_player:PlaySfxOneShot('01_gatcha_point_01')
	for i = 1, 3 do
		character_util.set_emotion(self.snowmans[i], { name = 'smile' })
	end
	character_util.set_emotion(self.snowman_kid, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(self.snowmans[2], { key = 'nightmare_desert_2_rescue_snowman_21', skip = true })
	-- 꼬마, right, smile, success, “그렇지, 기사님!”
	--music_player:PlaySfxOneShot('01_water_splash_01')
	character_util.set_direction(self.snowman_kid, 'right')
	character_util.set_anim_and_emotion(self.snowman_kid, { name = 'success', sfx_name = '01_water_splash_01' }, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(self.snowman_kid, { key = 'nightmare_desert_2_rescue_snowman_22', skip = true })
	-- 꼬마와 주인공 파티가 모두 화면에 잡히도록 카메라 이동.
	camera_util.move(self.snowman_kid.Position + vector(4, 0, 1), 1, { ignorecameragrids = true }) -- move_async ?
	-- 꼬마, smile, idle, “이거 받아주세요!”
	speech_bubble_util.show_speech_bubble_async(self.snowman_kid, { key = 'nightmare_desert_2_rescue_snowman_23', skip = true })
	-- 꼬마, 스타피스를 던져(throw 애니메이션 활용) 스타피스가 주인공 파티 앞에 드랍.
	character_util.set_anim(self.snowman_kid, { name = 'throw', loop = false })

	-- 스타피스 재생성하기 위한 처리
	local star_piece = get_field_object(self.starpiece_name)
	star_piece.Position = user_party_leader.Position - vector(1, 0, 0)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(self.snowman_kid.Position))

	-- 조작 캐릭터, victory_get.
	music_player:PlaySfxOneShot('01_stage_intro_jump_01')
	character_util.set_anim(user_party_leader, { name = 'victory_get', loop = false })
	wait_for_sec(2) -- victory_get 기다려줌
	character_util.remove_anim_and_emotion(user_party_leader)
	wait_for_sec(1.5)
	-- 누나, right, smile, idle, “덕분에 살았어요!”
	character_util.set_emotion(self.snowmans[2], 'smile')
	character_util.set_direction(self.snowmans[2], 'right')
	speech_bubble_util.show_speech_bubble_async(self.snowmans[2], { key = 'nightmare_desert_2_rescue_snowman_24', skip = true })
	-- 큰 형, right, smile, idle, “도와주셔서 감사합니다!”
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	character_util.set_emotion(self.snowmans[1], 'smile')
	character_util.set_direction(self.snowmans[1], 'right')
	speech_bubble_util.show_speech_bubble_async(self.snowmans[1], { key = 'nightmare_desert_2_rescue_snowman_25', skip = true })
	-- 설인들, 다시 물놀이 시작.
	self.water_play_coroutine = util.cs_generator(self.water_play, self, -1)
	coroutine_manager:StartCoroutine(stage.StageGameObject, self.water_play_coroutine)
	-- 카메라 원상복구, 이벤트 종료.
end

-- 물장구 치는 연출
function local_class:water_play(duration)
	local time_passed = 0

	music_player:PlaySfxOneShot('01_crowd_shout_03')
	character_util.set_anim_and_emotion(self.snowman_kid, { name = 'attack' }, { name = 'awesome' })
	character_util.set_anim_and_emotion(self.snowmans[1], { name = 'dance' }, { name = 'awesome' })
	character_util.set_anim_and_emotion(self.snowmans[2], { name = 'attack' }, { name = 'awesome' })
	character_util.set_anim_and_emotion(self.snowmans[3], { name = 'release' }, { name = 'awesome' })

	while time_passed < duration or duration == -1 do
		local random = random_util.get_random_int(1, 4)
		local target = self.snowman_kid
		if random < 4 then target = self.snowmans[random] end
		music_player_util.play_sfx({ sfx_name = '01_dive_01', parent = target, type_priority = 'event', player_priority = 'npc' })
		self.water_effect_pool:Instantiate(target.Position)

		time_passed = time_passed + 0.8
		wait_for_sec(0.8)
	end

	return
end

-- 설인 꼬마의 구조 요청
function local_class:requesting_rescue()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	camera_util.move_async(self.snowman_kid.Position, 1)

	-- “도와주세요! 가족들이 탈수로 쓰러졌어요!”
	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	speech_bubble_util.show_speech_bubble_async(self.snowman_kid, { key = 'nightmare_desert_2_rescue_snowman_1', skip = true, bubble_type = 'shout' })
	-- “쓰러진 가족들을 여기로 데려 와주세요!”
	speech_bubble_util.show_speech_bubble_async(self.snowman_kid, { key = 'nightmare_desert_2_rescue_snowman_2', skip = true, bubble_type = 'shout' })

	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })

	party_util.reset_controllers()
	field_ui_manager:Show()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
